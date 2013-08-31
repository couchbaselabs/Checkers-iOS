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

static NSCache * teamPieces;
+ (UIImage *) pieceForTeam:(int)team squareSize:(float)squareSize king:(BOOL)king
{
    if (teamPieces == nil) {
        teamPieces = [[NSCache alloc] init];
    }
    
    NSString * key = [NSString stringWithFormat:@"%d-%f-%d", team, squareSize, king];
    UIImage * piece = [teamPieces objectForKey:key];
    if (!piece) {
        CGFloat size = roundf(MIN(squareSize * 0.625, 1024));
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        CGContextSetFillColorWithColor(context, [AppStyle colorForTeam:team].CGColor);
        
        // Draw filled circle.
        CGContextFillEllipseInRect(context, CGRectMake(0, 0, size, size));
        
        // Draw king.
        if (king) {
            UIImage * kingImage = [UIImage imageNamed:@"King.png"];
            CGFloat inset = roundf(size * 0.2f);
            CGRect kingRect = CGRectInset(CGRectMake(0, 0, size, size), inset, inset);
            
            // Flip the coordinate system so the image will not be drawn upside down.
            CGContextTranslateCTM(context, 0, size);
            CGContextScaleCTM(context, 1.0, -1.0);
            
            CGContextDrawImage(context, kingRect, kingImage.CGImage);
        }
        
        UIGraphicsPopContext();
        
        piece = UIGraphicsGetImageFromCurrentImageContext();
        [teamPieces setObject:piece forKey:key];
        
        UIGraphicsEndImageContext();
    }
    
    return piece;
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
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(size + (2 * strokeWidth), size + (2 * strokeWidth)), NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        CGContextSetLineWidth(context, strokeWidth);
        CGContextSetStrokeColorWithColor(context, [AppStyle colorForTeam:team].CGColor);
        
        // Draw stroked circle.
        CGContextStrokeEllipseInRect(context, CGRectMake(strokeWidth, strokeWidth, size, size));
        
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
            NSUInteger previousSquareIndex = previousLocation.unsignedIntValue - 1;
            UIView * previousSquare = (squares.count > previousSquareIndex ? [squares objectAtIndex:previousSquareIndex] : nil);
            CGPoint previousPoint = previousSquare.center;
            float dx = (point.x - previousPoint.x);
            float dy = (point.y - previousPoint.y);
            
            CGPoint head = CGPointMake(point.x, point.y);
            CGPoint tail = CGPointMake((dx >= 0 ? point.x - size : point.x + size),
                                       (dy >= 0 ? point.y - size : point.y + size));
            
            [path addLineToPoint:tail];
            arrowPath = [UIBezierPath bezierArrowFromPoint:tail toPoint:head width:size * 0.75];
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
    CGContextAddPath(context, arrowPath.CGPath);
    CGContextStrokePath(context);
    CGContextAddPath(context, arrowPath.CGPath);
    CGContextFillPath(context);
    
    UIGraphicsPopContext();
    
    UIImage * trendingPathImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return trendingPathImage;
}

@end
