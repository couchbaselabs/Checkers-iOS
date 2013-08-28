//
//  AppDelegate.m
//  Checkers
//
//  Created by Wayne Carter on 8/19/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "AppDelegate.h"
#import <CouchbaseLite/CouchbaseLite.h>

#define kSyncURL @"http://sync.couchbasecloud.com:4984/checkers"

@implementation AppDelegate

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
    NSArray* repls = [_database replicateWithURL:[NSURL URLWithString:kSyncURL] exclusively:YES];
    for (CBLReplication* repl in repls) {
        repl.continuous = repl.persistent = YES;
        // TODO: Observe & display replication progress
    }

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

@end
