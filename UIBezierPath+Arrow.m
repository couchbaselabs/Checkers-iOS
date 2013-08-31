//
//  UIBezierPath+Arrow.m
//  Checkers
//
//  Created by Wayne Carter on 8/30/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "UIBezierPath+Arrow.h"

#define kArrowPointCount 3

@implementation UIBezierPath (Arrow)

+ (UIBezierPath *)bezierArrowFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint width:(CGFloat)width {
    CGFloat length = hypotf(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
    
    CGPoint points[kArrowPointCount];
    [self getAxisAlignedArrowPoints:points width:width length:length];
    
    CGAffineTransform transform = [self transformForStartPoint:startPoint endPoint:endPoint length:length];
    
    CGMutablePathRef cgPath = CGPathCreateMutable();
    CGPathAddLines(cgPath, &transform, points, sizeof points / sizeof *points);
    CGPathCloseSubpath(cgPath);
    
    UIBezierPath * bezierPath = [UIBezierPath bezierPathWithCGPath:cgPath];
    CGPathRelease(cgPath);
    
    return bezierPath;
}

+ (void)getAxisAlignedArrowPoints:(CGPoint[kArrowPointCount])points width:(CGFloat)width length:(CGFloat)length {
    points[0] = CGPointMake(0, width);
    points[1] = CGPointMake(length, 0);
    points[2] = CGPointMake(0, -width);
}

+ (CGAffineTransform)transformForStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint length:(CGFloat)length {
    CGFloat cosine = (endPoint.x - startPoint.x) / length;
    CGFloat sine = (endPoint.y - startPoint.y) / length;
    
    return (CGAffineTransform){ cosine, sine, -sine, cosine, startPoint.x, startPoint.y };
}

@end
