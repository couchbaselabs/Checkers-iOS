//
//  AppStyle.m
//  Checkers
//
//  Created by Wayne Carter on 8/19/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "AppStyle.h"
#import "UIBezierPath+Arrow.h"

@implementation AppStyle

+ (UIColor *)lightColor
{
    return RGB(255, 255, 255);
}

+ (UIColor *)mediumColor
{
    return RGB(239, 239, 239);
}

+ (UIColor *)darkColor
{
    return RGB(77, 77, 77);
}

+ (UIColor *)highlightColorForTeam:(int)team
{
    float h, s, b, a;
    UIColor * color = [AppStyle colorForTeam:team];
    [color getHue:&h saturation:&s brightness:&b alpha:&a];
    
    if (team == 1) return [UIColor colorWithHue:h saturation:s brightness:1.0 alpha:a];
    else return [UIColor colorWithHue:h saturation:s brightness:1.0 alpha:a];
}

+ (UIColor *)colorForTeam:(int)team
{
    if (team == 1) return RGB(58, 128, 223);
    else return RGB(223, 61, 61);
}

+ (UIColor *)validMoveColor
{
    return RGB(61, 223, 137);
}

static NSCache * pieces;
+ (UIImage *) pieceForTeam:(int)team squareSize:(float)squareSize king:(BOOL)king
{
    if (pieces == nil) {
        pieces = [[NSCache alloc] init];
    }
    
    NSString * key = [NSString stringWithFormat:@"%d-%f-%d", team, squareSize, king];
    UIImage * piece = [pieces objectForKey:key];
    if (!piece) {
        CGFloat size = roundf(MIN(squareSize * 0.625, 1024));
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(squareSize, squareSize), NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        CGContextSetFillColorWithColor(context, [AppStyle colorForTeam:team].CGColor);
        
        // Create/center drawing rect.
        CGRect rect = CGRectMake(0, 0, size, size);
        rect = CGRectOffset(rect, (squareSize - rect.size.width) / 2, (squareSize - rect.size.height) / 2);
        
        // Draw filled circle.
        CGContextFillEllipseInRect(context, rect);
        
        // Draw king.
        if (king) {
            UIImage * kingImage = [UIImage imageNamed:@"King.png"];
            CGFloat inset = roundf(size * 0.2f);
            CGRect kingRect = CGRectInset(rect, inset, inset);
            
            // Flip the coordinate system so the image will not be drawn upside down.
            CGContextTranslateCTM(context, 0, squareSize);
            CGContextScaleCTM(context, 1.0, -1.0);
            
            CGContextDrawImage(context, kingRect, kingImage.CGImage);
        }
        
        UIGraphicsPopContext();
        
        piece = UIGraphicsGetImageFromCurrentImageContext();
        [pieces setObject:piece forKey:key];
        
        UIGraphicsEndImageContext();
    }
    
    return piece;
}

static NSCache * pieceShadows;
+ (UIImage *)pieceShadowForTeam:(int)team squareSize:(float)squareSize
{
    if (pieceShadows == nil) {
        pieceShadows = [[NSCache alloc] init];
    }
    
    NSString * key = [NSString stringWithFormat:@"%d-%f", team, squareSize];
    UIImage * pieceShadow = [pieceShadows objectForKey:key];
    if (!pieceShadow) {
        CGFloat size = roundf(squareSize * 0.625);
        CGFloat strokeWidth = roundf(MAX(size * 0.04f, 1));
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(size + (2 * strokeWidth), size + (2 * strokeWidth)), NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        CGFloat dash[] = {0, strokeWidth * 3};
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineDash(context, 0.0, dash, 2);
        
        CGContextSetLineWidth(context, strokeWidth);
        CGContextSetStrokeColorWithColor(context, [AppStyle colorForTeam:team].CGColor);
        
        // Draw stroked circle.
        CGContextStrokeEllipseInRect(context, CGRectMake(strokeWidth, strokeWidth, size, size));
        
        UIGraphicsPopContext();
        
        pieceShadow = UIGraphicsGetImageFromCurrentImageContext();
        [pieceShadows setObject:pieceShadow forKey:key];
        
        UIGraphicsEndImageContext();
    }
    
    return pieceShadow;
}

static NSCache * validMoves;
+ (UIImage *)validMoveForTeam:(int)team squareSize:(float)squareSize
{
    if (validMoves == nil) {
        validMoves = [[NSCache alloc] init];
    }
    
    NSString * key = [NSString stringWithFormat:@"%d-%f", team, squareSize];
    UIImage * validMove = [validMoves objectForKey:key];
    if (!validMove) {
        CGFloat size = roundf(squareSize * 0.625);
        CGFloat strokeWidth = roundf(MAX(size * 0.04f, 1));
        size = MIN(size + (strokeWidth * 6.0f), 1024);
        
        //CGSize drawingSize = CGSizeMake(size + (2 * strokeWidth), size + (2 * strokeWidth));
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(squareSize, squareSize), NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        CGContextSetLineWidth(context, strokeWidth);
        CGContextSetStrokeColorWithColor(context, [AppStyle colorForTeam:team].CGColor);
        
        // Create/center drawing rect.
        CGRect rect = CGRectMake(0, 0, size, size);
        rect = CGRectOffset(rect, (squareSize - rect.size.width) / 2, (squareSize - rect.size.height) / 2);
        
        // Draw stroked circle.
        CGContextStrokeEllipseInRect(context, rect);
        
        UIGraphicsPopContext();
        
        validMove = UIGraphicsGetImageFromCurrentImageContext();
        [validMoves setObject:validMove forKey:key];
        
        UIGraphicsEndImageContext();
    }
    
    return validMove;
}

+ (UIImage *)strokeImage:(UIImage *)image forTeam:(int)team
{
    CGFloat stokeWidth = 4.0f;
    CGFloat radius = 4.0f;
    CGRect rect = CGRectMake(0, 0, image.size.width + (2 * stokeWidth), image.size.height + (2 * stokeWidth));
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    
    CGContextSetFillColorWithColor(context, [AppStyle colorForTeam:team].CGColor);
    
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + radius);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height - radius);
    CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + rect.size.height - radius, radius, M_PI / 4, M_PI / 2, 1);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height);
    CGContextAddArc(context, rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height - radius, radius, M_PI / 2, 0.0f, 1);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + radius);
    CGContextAddArc(context, rect.origin.x + rect.size.width - radius, rect.origin.y + radius, radius, 0.0f, -M_PI / 2, 1);
    CGContextAddLineToPoint(context, rect.origin.x + radius, rect.origin.y);
    CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + radius, radius, -M_PI / 2, M_PI, 1);
    
    CGContextFillPath(context);
    
    // Flip the coordinate system so the image will not be drawn upside down.
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectInset(rect, stokeWidth, stokeWidth), image.CGImage);
    
    UIGraphicsPopContext();
    
    UIImage * strokedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return strokedImage;
}

+ (UIImage *)drawTrendingPathForTeam:(int)team size:(float)size locations:(NSArray *)locations squares:(NSArray *)squares rect:(CGRect)rect
{
    if (locations.count < 2) return nil;
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    
    UIColor * color = [AppStyle highlightColorForTeam:team];
    
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, size);
    
    UIBezierPath * path = [[UIBezierPath alloc] init];
    UIBezierPath * arrowPath;
    int pathPointCount = 0;
    for (int i=0; i<locations.count; i++) {
        NSNumber * location = [locations objectAtIndex:i];
        NSUInteger squareIndex = location.unsignedIntValue - 1;
        UIView * square = (squares.count > squareIndex ? [squares objectAtIndex:squareIndex] : nil);
        CGPoint point = square.center;
        
        if (pathPointCount == 0) {
            [path moveToPoint:point];
            pathPointCount++;
        } else if (i == locations.count - 1) {
            NSNumber * previousLocation = [locations objectAtIndex:i - 1];
            UIView * previousSquare = (squares.count > previousLocation.unsignedIntValue - 1 ? [squares objectAtIndex:previousLocation.unsignedIntValue - 1] : nil);
            CGPoint previousPoint = previousSquare.center;
            float dx = (point.x - previousPoint.x);
            float dy = (point.y - previousPoint.y);
            
            float arrowSize = (size * 1.75);
            CGPoint head = CGPointMake(point.x, point.y);
            CGPoint tail = CGPointMake((dx >= 0 ? point.x - arrowSize : point.x + arrowSize),
                                       (dy >= 0 ? point.y - arrowSize : point.y + arrowSize));
            CGPoint lineHead = CGPointMake((dx >= 0 ? point.x - (arrowSize / 2) : point.x + (arrowSize / 2)),
                                           (dy >= 0 ? point.y - (arrowSize / 2) : point.y + (arrowSize / 2)));
            
            [path addLineToPoint:lineHead];
            arrowPath = [UIBezierPath bezierArrowFromPoint:tail toPoint:head width:arrowSize];
        } else {
            [path addLineToPoint:point];
            pathPointCount++;
        }
        
        if (i < locations.count - 1) {
            CGContextFillEllipseInRect(context, CGRectMake(square.center.x - size,
                                                           square.center.y - size,
                                                           size * 2,
                                                           size * 2));
        }
    }
    
    CGContextAddPath(context, path.CGPath);
    CGContextStrokePath(context);
    CGContextAddPath(context, arrowPath.CGPath);
    CGContextFillPath(context);
    
    UIGraphicsPopContext();
    
    UIImage * trendingPathImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return trendingPathImage;
}

@end
