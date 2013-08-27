//
//  UIView+Extended.m
//  Checkers
//
//  Created by Wayne Carter on 8/26/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "UIView+Extended.h"

@implementation UIView (Extended)

-(void)clearSubviews
{
    for (UIView * subview in [self subviews]) {
        [subview removeFromSuperview];
    }
}

-(void)sizeToFitSubviews
{
    float width = 0;
    float height = 0;
    
    for (UIView * subview in [self subviews]) {
        float subviewWidth = subview.frame.origin.x + subview.frame.size.width;
        float subviewHeight = subview.frame.origin.y + subview.frame.size.height;
        
        width = MAX(subviewWidth, width);
        height = MAX(subviewHeight, height);
    }
    
    [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, width, height)];
}

@end
