//
//  User.h
//  Checkers
//
//  Created by Wayne Carter on 8/25/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject {
@protected
    NSMutableDictionary * data;
}

- (id)initWithData:(NSData *)data;
- (id)initWithDictionary:(NSMutableDictionary *)dictionary;

@property (readonly) NSNumber * team;
@property (readonly) NSString * facebookId;

@end
