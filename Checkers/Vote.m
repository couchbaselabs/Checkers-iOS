//
//  Vote.m
//  Checkers
//
//  Created by Wayne Carter on 8/25/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "Vote.h"

@implementation Vote

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

-(void)setGame:(NSNumber *)game {
    [data setObject:game forKey:@"game"];
}

-(NSNumber *)turn {
    return [data objectForKey:@"turn"];
}

-(void)setTurn:(NSNumber *)turn {
    [data setObject:turn forKey:@"turn"];
}

-(NSNumber *)team {
    return [data objectForKey:@"team"];
}

-(void)setTeam:(NSNumber *)team {
    [data setObject:team forKey:@"team"];
}

-(NSNumber *)piece {
    return [data objectForKey:@"piece"];
}

-(void)setPiece:(NSNumber *)piece {
    [data setObject:piece forKey:@"piece"];
}

-(NSArray *)locations {
    return [data objectForKey:@"locations"];
}

-(void)setLocations:(NSArray *)locations {
    [data setObject:locations forKey:@"locations"];
}

@end
