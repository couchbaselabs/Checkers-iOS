//
//  User.m
//  Checkers
//
//  Created by Wayne Carter on 8/25/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "User.h"

@implementation User

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

-(NSNumber *)team {
    return [data objectForKey:@"team"];
}

-(NSString *)facebookId {
    return [data objectForKey:@"facebookId"];
}

@end
