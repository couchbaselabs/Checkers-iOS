//
//  AppDelegate.m
//  Checkers
//
//  Created by Wayne Carter on 8/19/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "AppDelegate.h"
#import <CouchbaseLite/CouchbaseLite.h>

@implementation AppDelegate
{
    GameViewController * gameViewController;
    GameController * gameController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    gameViewController = [[GameViewController alloc] init];
    self.viewController = gameViewController;
    gameController = [[GameController alloc] initWithGameViewController:gameViewController];

    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
}

@end
