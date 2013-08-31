//
//  UIBezierPath+Arrow.h
//  Checkers
//
//  Created by Wayne Carter on 8/30/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (Arrow)

+ (UIBezierPath *)bezierArrowFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint width:(CGFloat)width;

@end
