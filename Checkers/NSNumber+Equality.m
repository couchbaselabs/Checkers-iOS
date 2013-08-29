//
//  NSNumber+Equality.m
//  Checkers
//
//  Created by Wayne Carter on 8/29/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "NSNumber+Equality.h"

@implementation NSNumber (Equality)

+(BOOL)number:(NSNumber *)number1 isEqualToNumber:(NSNumber *)number2
{
    if (number1 == nil && number2 == nil) {
        return YES;
    } else if (number1 == nil || number2 == nil) {
        return NO;
    }
    
    return [number1 isEqualToNumber:number2];
}

@end
