//
//  Facebook.h
//  Checkers
//
//  Created by Wayne Carter on 8/27/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <Foundation/Foundation.h>

// Completion block for performRequestWithHandler.
typedef void(^FacebookPictureHandler)(UIImage * image);

@interface Facebook : NSObject

+(void)pictureWithSize:(int)size handler:(FacebookPictureHandler)handler;

@end
