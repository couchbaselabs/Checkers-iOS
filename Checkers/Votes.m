//
//  Votes.m
//  Checkers
//
//  Created by Wayne Carter on 8/28/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "Votes.h"

// Moves
@implementation VotesMove

-(id)initWithData:(NSDictionary *)theData
{
    return [super initWithData:theData];
}

-(NSNumber *)count
{
    return [data objectForKey:@"count"];
}

@end

// Votes
@implementation Votes

-(id)initWithData:(NSData *)theData {
    NSMutableDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:theData options:(NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves) error:nil];
    
    return [self initWithDictionary:dictionary];
}

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [self init]) {
        data = [dictionary mutableCopy];
    }
    
    return self;
}

-(NSNumber *)game {
    return [data objectForKey:@"game"];
}

-(NSNumber *)turn {
    return [data objectForKey:@"turn"];
}

-(NSNumber *)team {
    return [data objectForKey:@"team"];
}

-(NSNumber *)count {
    return [data objectForKey:@"count"];
}

-(NSArray *)moves {
    if (moves == nil) {
        moves = [NSMutableArray array];
        
        for (NSDictionary * moveData in [data objectForKey:@"moves"]) {
            [moves addObject:[[VotesMove alloc] initWithData:moveData]];
        }
    }
    
    return moves;
}

@end