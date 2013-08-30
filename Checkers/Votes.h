//
//  Votes.h
//  Checkers
//
//  Created by Wayne Carter on 8/28/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Game.h"

// Move
@interface VotesMove : GameMove

- (id)initWithData:(NSDictionary *)data;

@property (readonly) NSNumber * count;

@end

// Votes
@interface Votes : NSObject {
@protected
    NSMutableDictionary * data;
@private
    NSMutableArray * moves;
}

- (id)initWithData:(NSData *)data;
- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (readonly) NSNumber * game;
@property (readonly) NSNumber * turn;
@property (readonly) NSNumber * team;
@property (readonly) NSNumber * count;
@property (readonly) NSArray * moves;

@end
