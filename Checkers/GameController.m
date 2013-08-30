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
//#define kSyncURL @"http://Waynes-MacBook-Pro-2.local:4984/checkers"

#define kGameDocID @"game-1"

@implementation GameController
{
    GameViewController * gameViewController;
    NSThread* bgThread;
    CBLDatabase* database;
    CBLReplication* pull;
    CBLDocument* userDoc, *gameDoc, *voteDoc, *votesDoc;
    NSString* userID;
}

-(id)initWithGameViewController:(GameViewController *)theGameViewController {
    if (self = [super init]) {
        gameViewController = theGameViewController;
        gameViewController.delegate = self;
        // GameController runs Couchbase Lite on a background thread.
        // Methods prefixed with "_" run on that thread.
        bgThread = [[NSThread alloc] initWithTarget:self
                                           selector:@selector(_couchbaseThread)
                                             object:nil];
        [bgThread start];
    }
    return self;
}

- (void) _couchbaseThread {
    // Initialize Couchbase Lite:
    NSLog(@"Initializing Couchbase Lite");
    NSError* error;
    database = [[CBLManager sharedInstance] createDatabaseNamed:@"checkers" error:&error];
    if (!database) {
        NSLog(@"FATAL: Couldn't open database: %@", error);
        abort();
    }
#ifdef kSyncURL
    NSArray* repls = [database replicateWithURL:[NSURL URLWithString:kSyncURL] exclusively:YES];
    for (CBLReplication* repl in repls) {
        repl.continuous = repl.persistent = YES;
    }
    // Observe the pull replication to detect when it's caught up:
    pull = repls[0];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(_pullReplicationChanged:)
                                                 name: kCBLReplicationChangeNotification
                                               object: pull];
    NSLog(@"Initialized CouchbaseLite; waiting for replication to catch up...");
#endif

    [[NSRunLoop currentRunLoop] run];
}

// Called when a replication's state changes
- (void) _pullReplicationChanged: (NSNotification*)n {
    CBLReplication* repl = n.object;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = (repl.mode == kCBLReplicationActive);
    if (repl.mode == kCBLReplicationIdle) {
        [self _gameReady];
    }
}

- (void) _gameReady {
    // Load the current game state:
    gameDoc = database[kGameDocID];
    NSDictionary* gameProps = gameDoc.properties;
    if (gameProps) {
        // OK, we're ready to start; stop listening for replication notifications:
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name: kCBLReplicationChangeNotification
                                                      object: pull];
        pull = nil;
    } else {
        // Game document isn't available; initial replication must've failed, or the server
        // somehow doesn't have a game set up yet. Either way, give up for now.
        NSLog(@"Game doc '%@' isn't available yet; waiting for replicator...", kGameDocID);
        return;
    }

    NSLog(@"GameController: Initial game data ready, updating UI...");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_updateGame:)
                                                 name:kCBLDocumentChangeNotification
                                               object:gameDoc];

    // Get or create my unique player ID:
    userID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserID"];
    if (!userID) {
        userID = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:userID forKey:@"UserID"];
        NSLog(@"Generated user ID '%@'", userID);
    }

    // Load or create my user document:
    userDoc = database[[NSString stringWithFormat:@"user:%@", userID]];
    if (userDoc.currentRevision == nil) {
        // Create an initial blank user document
        NSError* error;
        if (![userDoc putProperties:@{} error:&error]) {
            NSLog(@"WARNING: Couldn't save user doc '%@': %@", userDoc, error);
        }
    }
    NSDictionary* userProps = userDoc.properties;
    
    // Listen for user changes (e.g. team change).
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_updateUser:)
                                                 name:kCBLDocumentChangeNotification
                                               object:userDoc];
    
    // Listen for vote changes (e.g. user voted).
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_updateVote:)
                                                 name:kCBLDocumentChangeNotification
                                               object:voteDoc];

    // Load the voting-statistics document:
    votesDoc = database[@"votes"];
    NSDictionary* votesProps = votesDoc.properties ?: @{};
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_updateVotes:)
                                                 name:kCBLDocumentChangeNotification
                                               object:votesDoc];

    // Load my current vote (if any):
    voteDoc = database[[NSString stringWithFormat:@"vote:%@", userID]];
    NSDictionary* voteProps = voteDoc.properties ?: @{};

    // Set up the UI code:
    dispatch_async(dispatch_get_main_queue(), ^{
        gameViewController.game = [[Game alloc] initWithDictionary:gameProps];
        gameViewController.user = [[User alloc] initWithDictionary:userProps];
        gameViewController.vote = [[Vote alloc] initWithDictionary:voteProps];
        gameViewController.votes = [[Votes alloc] initWithDictionary:votesProps];
    });
}

- (void)_updateGame:(NSNotification*)n {
    // Update gameViewController.game when we receive data changes from server.
    NSLog(@"** Got game document: %@", gameDoc.currentRevision);
    NSDictionary* properties = gameDoc.properties;
    NSAssert(properties, @"Missing game document!");

    dispatch_async(dispatch_get_main_queue(), ^{
        gameViewController.game = [[Game alloc] initWithDictionary:properties];
    });
}

- (void)_updateUser:(NSNotification*)n {
    // Update gameViewController.game when we receive data changes from server.
    NSLog(@"** Got user document: %@", userDoc.currentRevision);
    NSDictionary* properties = userDoc.properties;
    NSAssert(properties, @"Missing user document!");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        gameViewController.user = [[User alloc] initWithDictionary:properties];
    });
}

- (void)_updateVote:(NSNotification*)n {
    // Update gameViewController.game when we receive data changes from server.
    NSLog(@"** Got vote document: %@", voteDoc.currentRevision);
    NSDictionary* properties = voteDoc.properties;
    NSAssert(properties, @"Missing vote document!");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        gameViewController.vote = [[Vote alloc] initWithDictionary:properties];
    });
}

- (void)_updateVotes:(NSNotification*)n {
    // Update gameViewController.votes when we receive data changes from server.
    NSLog(@"** Got votes document: %@", votesDoc.currentRevision);
    NSDictionary* properties = votesDoc.properties;
    NSAssert(properties, @"Missing votes document!");

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


-(void)gameViewController:(GameViewController *)theGameViewController
            didSelectTeam:(GameTeam *)team {
    [self performSelector: @selector(_submitTeam:)
                 onThread: bgThread
               withObject: @(team.number)
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

-(void)gameViewController:(GameViewController *)theGameViewController
         didMakeValidMove:(GameValidMove *)validMove {
    [self performSelector: @selector(_submitMove:)
                 onThread: bgThread
               withObject: [NSArray arrayWithObjects:theGameViewController.game, validMove, nil]
            waitUntilDone:NO];
}

- (void)_submitMove:(NSArray*)gameAndValidMove {
    Game* game = (Game *)gameAndValidMove[0];
    GameValidMove* validMove = (GameValidMove *)gameAndValidMove[1];
    
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
    
    // On 1st vote per game we update the user doc w/ the current game number.
    if (![NSNumber number:userDoc.properties[@"game"] isEqualToNumber:game.number]) {
        NSError* error = updateDoc(userDoc, ^(NSMutableDictionary *props) {
            props[@"game"] = game.number;
            
            return YES;
        });
        if (error) {
            NSLog(@"WARNING: Couldn't save vote doc: %@", error);
        }
    }
}

-(void)gameViewController:(GameViewController *)theGameViewController buttonTapped:(GameViewControllerButton)button {
    if (button == CBCGameViewControllerButtonFacebook) {
        if (Facebook.composeServiceAvailable)
        {
            SLComposeViewController * sheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            [sheet setInitialText:@"Couchbase Checkers\n\n"];
            
            [sheet addImage:gameViewController.gameAsImage];
            [sheet addURL:[NSURL URLWithString:@"http://www.couchbase.com/checkers"]];
            
            [gameViewController presentViewController:sheet animated:YES completion:nil];
        }
    } else if (button == CBCGameViewControllerButtonTwitter) {
        if (Twitter.composeServiceAvailable)
        {
            SLComposeViewController * sheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            //[sheet setInitialText:@"Couchbase Checkers\n\n"];
            
            [sheet addImage:gameViewController.gameAsImage];
            [sheet addURL:[NSURL URLWithString:@"http://www.couchbase.com/checkers"]];
            
            [gameViewController presentViewController:sheet animated:YES completion:nil];
        }
    }
}

@end
