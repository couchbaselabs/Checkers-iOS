//
//  Twitter.m
//  Checkers
//
//  Created by Wayne Carter on 8/28/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "Twitter.h"
#import <Social/Social.h>

@implementation Twitter

+(BOOL)composeServiceAvailable {
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

@end
