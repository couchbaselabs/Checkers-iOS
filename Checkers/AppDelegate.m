//
//  AppDelegate.m
//  Checkers
//
//  Created by Wayne Carter on 8/19/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "AppDelegate.h"
#import <CouchbaseLite/CouchbaseLite.h>

//#define kSyncURL @"http://sync.couchbasecloud.com:4984/checkers"
#define kSyncURL @"http://localhost:5984/checkers"

@implementation AppDelegate
{
    GameViewController * gameViewController;
    GameController * gameController;
    CBLReplication* _pull;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

    // Initialize Couchbase Lite:
    NSError* error;
    self.database = [[CBLManager sharedInstance] createDatabaseNamed:@"checkers" error:&error];
    if (!self.database) {
        NSLog(@"FATAL: Couldn't open database: %@", error);
        abort();
    }
#ifdef kSyncURL
    NSArray* repls = [_database replicateWithURL:[NSURL URLWithString:kSyncURL] exclusively:YES];
    for (CBLReplication* repl in repls) {
        repl.continuous = repl.persistent = YES;
    }
    // Observe the pull replication to detect when it's caught up:
    _pull = repls[0];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(pullReplicationChanged:)
                                                 name: kCBLReplicationChangeNotification
                                               object: _pull];
    NSLog(@"Initialized CouchbaseLite; waiting for replication to catch up...");
#endif

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    gameViewController = [[GameViewController alloc] init];
    self.viewController = gameViewController;
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    gameController = [[GameController alloc] initWithGameViewController:gameViewController
                                                               database:_database];
}

void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
}

// Called when a replication's state changes
- (void) pullReplicationChanged: (NSNotification*)n {
    CBLReplication* repl = n.object;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = (repl.mode == kCBLReplicationActive);
    if (repl.mode == kCBLReplicationIdle) {
        // When pull goes idle, tell the GameController and then stop observing:
        [gameController gameReady];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name: kCBLReplicationChangeNotification
                                                      object: repl];
    }
}

@end
