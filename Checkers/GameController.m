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

//#define kSyncURL @"http://sync.couchbasecloud.com:4984/checkers"
#define kSyncURL @"http://localhost:5984/checkers"

#define kGameDocID @"game-1"

@interface GameController ()
@property id gameNumber;
@end

@implementation GameController
{
    GameViewController * gameViewController;
    NSThread* bgThread;
    CBLDatabase* database;
    CBLReplication* pull;
    CBLDocument* userDoc, *gameDoc, *voteDoc;
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
        // When pull goes idle, tell the GameController and then stop observing:
        [self _gameReady];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name: kCBLReplicationChangeNotification
                                                      object: repl];
    }
}

- (void) _gameReady {
    NSLog(@"GameController: Initial game data ready, updating UI...");
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

    // Load the current game state:
    gameDoc = database[kGameDocID];
    NSDictionary* gameProps = gameDoc.properties;
    self.gameNumber = gameProps[@"number"];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateGame:)
                                                 name:kCBLDocumentChangeNotification
                                               object:gameDoc];

    // Load my current vote (if any):
    voteDoc = database[[NSString stringWithFormat:@"vote:%@", userID]];
    NSDictionary* voteProps = voteDoc.properties;
    if (!voteProps)
        voteProps = @{};

    // Set up the UI code:
    dispatch_async(dispatch_get_main_queue(), ^{
        gameViewController.game = [[Game alloc] initWithDictionary:gameProps];
        gameViewController.user = [[User alloc] initWithDictionary:userProps];
        gameViewController.vote = [[Vote alloc] initWithDictionary:voteProps];
    });
}

- (void)_updateGame:(NSNotification*)n {
    // Update gameViewController.game when we receive data changes from server.
    NSLog(@"** Got game document: %@", gameDoc.currentRevision);
    NSDictionary* properties = gameDoc.properties;
    NSAssert(properties, @"Missing game document!");

    dispatch_async(dispatch_get_main_queue(), ^{
        self.gameNumber = properties[@"number"];
        gameViewController.game = [[Game alloc] initWithDictionary:properties];
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
               withObject: validMove
            waitUntilDone:NO];
}

- (void)_submitMove:(GameValidMove*)validMove {
    NSError* error = updateDoc(voteDoc, ^(NSMutableDictionary *props) {
        props[@"game"] = self.gameNumber;
        props[@"team"] = @(validMove.team);
        props[@"pieces"] = @(validMove.piece);
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
