//
//  GameController.h
//  Checkers
//
//  Created by Wayne Carter on 8/26/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameViewController.h"

@interface GameController : NSObject<GameViewControllerDelegate> {
@private
    GameViewController * gameViewController;
}

-(id)initWithGameViewController:(GameViewController *)gameViewController;

@end
