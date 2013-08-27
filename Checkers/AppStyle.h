//
//  AppStyle.h
//  Checkers
//
//  Created by Wayne Carter on 8/19/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RGB(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define RGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]

@interface AppStyle : NSObject

+ (UIColor *)lightColor;
+ (UIColor *)mediumColor;
+ (UIColor *)darkColor;

+ (UIColor *)colorForTeam:(int)team;

+ (UIColor *)validMoveColor;

+ (UIImage *)pieceForTeam:(int)team squareSize:(float)squareSize king:(BOOL)king;
+ (UIImage *)validMoveForTeam:(int)team squareSize:(float)squareSize;

+ (UIImage *)strokeImage:(UIImage *)image forTeam:(int)team;

@end
