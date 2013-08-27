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

-(id)initWithDictionary:(NSMutableDictionary *)dictionary
{
    if (self = [self init]) {
        data = dictionary;
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

-(NSNumber *)piece {
    return [data objectForKey:@"piece"];
}

-(NSArray *)locations {
    return [data objectForKey:@"locations"];
}

@end
