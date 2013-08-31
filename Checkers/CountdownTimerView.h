//
//  CountdownTimerView.h
//  Checkers
//
//  Created by Wayne Carter on 8/31/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CountdownTimerView;

@protocol CountdownTimerViewDelegate <NSObject>

-(void)countdownTimerViewTimeout:(CountdownTimerView *)countdownTimerView;

@end

@interface CountdownTimerView : UILabel {
    NSDate * time;
    BOOL timedOut;
}

@property id<CountdownTimerViewDelegate> delegate;
@property NSDate * time;

@end
