//
//  CountdownTimerView.m
//  Checkers
//
//  Created by Wayne Carter on 8/31/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "CountdownTimerView.h"

@implementation CountdownTimerView

-(id)init {
    if (self = [super init]) {
        [self tick];
    }
    
    return self;
}

-(NSDate *)time {
    return time;
}

-(void)setTime:(NSDate *)theTime {
    time = theTime;
    timedOut = NO;
    
    self.hidden = NO;
}

-(NSString *)timeStringValue {
    NSTimeInterval secondsRemaining = [time timeIntervalSinceNow];
    
    if (secondsRemaining > 0) {
        int seconds =  floor(secondsRemaining);
        
        NSString * secondsString = [NSString stringWithFormat:@"%d", seconds];
        while (secondsString.length < 2) {
            secondsString = [@"0" stringByAppendingString: secondsString];
        }
        
        return [NSString stringWithFormat:@"%@", secondsString];
    } else {
        return @"00";
    }
}

-(void)tick {
    NSTimeInterval delayInSeconds = (timedOut ? 0.5 : 0.01);
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    NSTimeInterval secondsRemaining = [time timeIntervalSinceNow];
    NSString * timeStringValue = self.timeStringValue;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.text = timeStringValue;
        
        if (secondsRemaining < 0) {
            if (!timedOut) {
                [self.delegate countdownTimerViewTimeout:self];
            } else {
                self.hidden = !self.hidden;
            }
            
            timedOut = YES;
        } else {
            timedOut = NO;
        }
        
        dispatch_after(delay, queue, ^{
            [self tick];
        });
    });
}

@end
