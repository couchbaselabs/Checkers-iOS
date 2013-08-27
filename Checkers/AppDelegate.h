//
//  AppDelegate.h
//  Checkers
//
//  Created by Wayne Carter on 8/19/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
@private
    GameViewController * gameViewController;
    GameController * gameController;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) GameViewController *viewController;

@end
