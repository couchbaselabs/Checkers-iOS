//
//  GameController.m
//  Checkers
//
//  Created by Wayne Carter on 8/26/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "GameController.h"
#import "Facebook.h"
#import "Twitter.h"
#import <Social/Social.h>
#import <CouchbaseLite/CouchbaseLite.h>
#import "NSNumber+Equality.h"

#define kSyncURL @"http://checkers.sync.couchbasecloud.com/checkers"
//#define kSyncURL @"http://sync.couchbasecloud.com/checkers"
//#define kSyncURL @"http://localhost:4984/checkers"
//#define kSyncURL @"http://tyrathect.local:4984/checkers"
//#define kSyncURL @"http://192.168.1.110:4984/checkers"
//#define kSyncURL @"http://192.168.1.102:8888/checkers"

@implementation GameController
{
    GameViewController * gameViewController;
    NSThread* couchbaseThread;
    
    CBLDatabase* database;
    NSArray* replications;
    CBLLiveQuery* gamesLiveQuery;
    
    CBLDocument* userDoc, *gameDoc, *voteDoc, *votesDoc;
}

-(id)initWithGameViewController:(GameViewController *)theGameViewController {
    if (self = [super init]) {
        gameViewController = theGameViewController;
        gameViewController.delegate = self;
        
        // GameController runs Couchbase Lite on a background thread.
        // Methods prefixed with "_" run on that thread.
        couchbaseThread = [[NSThread alloc] initWithTarget:self selector:@selector(_initCouchbase) object:nil];
        [couchbaseThread start];
    }
    
    return self;
}

- (void) _initCouchbase {
    // Initialize Couchbase Lite:
    NSLog(@"Initializing Couchbase Lite");
    NSError* error;
    database = [[CBLManager sharedInstance] createDatabaseNamed:@"checkers" error:&error];
    if (!database) {
        NSLog(@"FATAL: Couldn't open database: %@", error);
        abort();
    }
    
    // Configure the replications.
    replications = [database replicateWithURL:[NSURL URLWithString:kSyncURL] exclusively:YES];
    NSDictionary* filterparams = [[NSDictionary alloc] initWithObjectsAndKeys:@"game", @"channels", nil];
    for (CBLReplication* replication in replications) {
        replication.continuous = replication.persistent = YES;
        if(replication.pull) {
            replication.filter = @"sync_gateway/bychannel";
            replication.query_params = filterparams;
        }
    }
    
    // Get/create unique player ID.
    NSString* userID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserID"];
    if (!userID) {
        userID = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:userID forKey:@"UserID"];
        NSLog(@"Generated user ID '%@'", userID);
    }
    
    // Load/create user document
    userDoc = database[[NSString stringWithFormat:@"user:%@", userID]];
    if (userDoc.currentRevision == nil) {
        // Create an initial blank user document
        NSError* error;
        if (![userDoc putProperties:@{} error:&error]) {
            NSLog(@"WARNING: Couldn't save user doc '%@': %@", userDoc, error);
        }
    }
    NSDictionary* userProps = userDoc.properties;
    
    // Load vote document.
    voteDoc = database[[NSString stringWithFormat:@"vote:%@", userID]];
    NSDictionary* voteProps = voteDoc.properties ?: @{};
    
    // Create view for games by start time.
    CBLView * gamesByStartTime = [database viewNamed: @"gamesByStartTime"];
    if (!gamesByStartTime.mapBlock) {
        [gamesByStartTime setMapBlock: MAPBLOCK({
            if ([doc[@"_id"] hasPrefix:@"game:"] && doc[@"startTime"]) {
                emit(doc[@"startTime"], doc);
            }
        }) reduceBlock: nil version: @"1.0"];
        // NOTE: Make sure to bump version any time you change the MAPBLOCK body!
    }
    // Create/observe live query for the latest game.
    gamesLiveQuery = gamesByStartTime.query.asLiveQuery;
    gamesLiveQuery.limit = 1;
    gamesLiveQuery.descending = YES;
    [gamesLiveQuery addObserver:self forKeyPath:@"rows" options:0 context:NULL];
    
    // Set up the UI.
    [self _updateGame];
    dispatch_async(dispatch_get_main_queue(), ^{
        gameViewController.user = [[User alloc] initWithDictionary:userProps];
        gameViewController.vote = [[Vote alloc] initWithDictionary:voteProps];
    });

    [[NSRunLoop currentRunLoop] run];
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (object == gamesLiveQuery) {
        [self _updateGame];
    }
}

- (void) _updateGame
{
    for (CBLQueryRow* row in [gamesLiveQuery rows]) {
        // Update gameViewController.game when we receive data changes from server.
        gameDoc = row.document;
        NSLog(@"** Got game document: %@", gameDoc.currentRevision);
        NSDictionary* gameProperties = gameDoc.properties;
        
        // Get matching votes doc.
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kCBLDocumentChangeNotification
                                                      object:votesDoc];
        votesDoc = database[gameProperties[@"votesDoc"]];
        NSLog(@"** Got votes document: %@", votesDoc.currentRevision);
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_updateVotes:)
                                                     name:kCBLDocumentChangeNotification
                                                   object:votesDoc];
        NSDictionary* votesProperties = votesDoc.properties;
        
        // Update UI.
        dispatch_async(dispatch_get_main_queue(), ^{
            gameViewController.game = [[Game alloc] initWithDictionary:gameProperties];
            gameViewController.votes = [[Votes alloc] initWithDictionary:votesProperties];
        });
    }
}

- (void)_updateVotes:(NSNotification*)n {
    // Update gameViewController.votes when we receive data changes from server.
    NSLog(@"** Got votes document: %@", votesDoc.currentRevision);
    NSDictionary* properties = votesDoc.properties;

    dispatch_async(dispatch_get_main_queue(), ^{
        gameViewController.votes = [[Votes alloc] initWithDictionary:properties];
    });
}


#pragma mark - USER ACTIONS


// Subroutine to update a document, with retry on conflicts.
static NSError* updateDoc(CBLDocument* doc, BOOL (^block)(NSMutableDictionary*)) {
    NSError* error;
    do {
        NSMutableDictionary* props = [doc.properties mutableCopy];
        if (!props)
            props = [NSMutableDictionary dictionary];
        if (!block(props)) { // Invoke the callback to update the properties!
            return nil;
        }
        if ([doc putProperties: props error: &error]) {
            NSLog(@"Saved %@", doc);
            return nil; // success
        }
    } while (error.code == 409 && [error.domain isEqualToString: CBLHTTPErrorDomain]);
    return error;
}


-(void)gameViewController:(GameViewController *)theGameViewController didSelectTeam:(GameTeam *)team {
    // Submit on Couchbase thread.
    [self performSelector:@selector(_submitTeam:)
                 onThread:couchbaseThread
               withObject:@(team.number)
            waitUntilDone:NO];
}

-(void)gameViewController:(GameViewController *)theGameViewController didMakeValidMove:(GameValidMove *)validMove {
    // Submit on Couchbase thread.
    [self performSelector:@selector(_submitMove:)
                 onThread:couchbaseThread
               withObject:[NSArray arrayWithObjects:theGameViewController.game, validMove, nil]
            waitUntilDone:NO];
}

- (void)_submitTeam: (NSNumber*)teamNumber {
    NSError* error = updateDoc(userDoc, ^(NSMutableDictionary *props) {
        props[@"team"] = teamNumber;
        return YES;
    });
    if (error) {
        NSLog(@"WARNING: Couldn't save user doc: %@", error);
    }
}

- (void)_submitMove:(NSArray*)gameAndValidMove {
    Game* game = (Game *)gameAndValidMove[0];
    GameValidMove* validMove = (GameValidMove *)gameAndValidMove[1];
    
    // On the 1st vote per game update the user doc w/ the current game number.
    if (![NSNumber number:userDoc.properties[@"game"] isEqualToNumber:game.number]) {
        NSError* error = updateDoc(userDoc, ^(NSMutableDictionary *props) {
            props[@"game"] = game.number;
            
            return YES;
        });
        if (error) {
            NSLog(@"WARNING: Couldn't save user doc: %@", error);
        }
    }
    
    NSError* error = updateDoc(voteDoc, ^(NSMutableDictionary *props) {
        props[@"game"] = game.number;
        props[@"turn"] = game.turn;
        props[@"team"] = @(validMove.team);
        props[@"piece"] = @(validMove.piece);
        props[@"locations"] = validMove.locations;
        
        return YES;
    });
    if (error) {
        NSLog(@"WARNING: Couldn't save vote doc: %@", error);
    }
}

-(void)gameViewController:(GameViewController *)theGameViewController buttonTapped:(GameViewControllerButton)button {
    if (button == CBCGameViewControllerButtonFacebook) {
        if (Facebook.composeServiceAvailable)
        {
            SLComposeViewController * sheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            if (theGameViewController.game.applicationName) {
                [sheet setInitialText:[NSString stringWithFormat:@"%@\n\n", theGameViewController.game.applicationName]];
            }
            
            [sheet addImage:gameViewController.gameAsImage];
            [sheet addURL:[NSURL URLWithString:theGameViewController.game.applicationUrl]];
            
            [gameViewController presentViewController:sheet animated:YES completion:nil];
        }
    } else if (button == CBCGameViewControllerButtonTwitter) {
        if (Twitter.composeServiceAvailable)
        {
            SLComposeViewController * sheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            
            [sheet addImage:gameViewController.gameAsImage];
            [sheet addURL:[NSURL URLWithString:theGameViewController.game.applicationUrl]];
            
            [gameViewController presentViewController:sheet animated:YES completion:nil];
        }
    }
}

@end
