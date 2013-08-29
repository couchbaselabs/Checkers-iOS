//
//  Votes.h
//  Checkers
//
//  Created by Wayne Carter on 8/28/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Votes : NSObject {
@protected
    NSMutableDictionary * data;
}

- (id)initWithData:(NSData *)data;
- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (readonly) NSNumber * game;
@property (readonly) NSNumber * turn;
@property (readonly) NSNumber * team;
@property (readonly) NSNumber * count;

@end
