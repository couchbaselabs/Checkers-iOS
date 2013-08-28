//
//  Facebook.m
//  Checkers
//
//  Created by Wayne Carter on 8/27/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "Facebook.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@implementation Facebook

ACAccountStore * accountStore;
+(ACAccountStore *)accountStore {
    if (!accountStore) {
        accountStore = [[ACAccountStore alloc] init];
    }
    
    return accountStore;
}

+(NSDictionary *)accessOptions {
    return @{ACFacebookAppIdKey: @"581783778545478", ACFacebookPermissionsKey: @[@"email"]};;
}

BOOL accessRejected;
+(BOOL)accessRejected {
    return accessRejected;
}

+(UIImage *)pictureWithSize:(int)size
{
    NSNumber * key = [NSNumber numberWithInt:size];
    
    return [pictures objectForKey:key];
}

+(void)pictureWithSize:(int)size handler:(FacebookPictureHandler)handler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [Facebook doPictureWithSize:size handler:handler];
    });
}

dispatch_semaphore_t pictures_semaphore;
NSMutableDictionary * pictures;
+(void)doPictureWithSize:(int)size handler:(FacebookPictureHandler)handler
{
    @synchronized(Facebook.class) {
        if (pictures == nil) {
            pictures_semaphore = dispatch_semaphore_create(1);
            pictures = [[NSMutableDictionary alloc] init];
        }
    }
    
    // Wait so we can't hammer FB w/ requests.
    dispatch_semaphore_wait(pictures_semaphore, DISPATCH_TIME_FOREVER);
    
    // If we already have the pic cached then return it.
    UIImage * picture = [Facebook pictureWithSize:size];
    if (picture) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(picture);
        });
        
        return;
    }
    
    // If we have already been rejected access then just return nil.
    if (Facebook.accessRejected) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(nil);
        });
        
        return;
    }
    
    ACAccountType * accountType = [Facebook.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    [accountStore requestAccessToAccountsWithType:accountType options:Facebook.accessOptions completion:
     ^(BOOL granted, NSError *e) {
         if (granted) {
             NSArray * accounts = [Facebook.accountStore accountsWithAccountType:accountType];
             ACAccount * account = [accounts lastObject];
             
             NSURL * url = [NSURL URLWithString:@"https://graph.facebook.com/me"];
             SLRequest * request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodGET URL:url parameters:nil];
             
             request.account = account;
             [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                 UIImage * picture;
                 
                 if (responseData) {
                     NSDictionary * data = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
                     NSString * userId = data[@"id"];
                     NSURL * pictureUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=%d&height=%d", userId, size, size]];
                     
                     picture = [UIImage imageWithData:[NSData dataWithContentsOfURL:pictureUrl]];
                 }
                 
                 if (picture) {
                     NSNumber * key = [NSNumber numberWithInt:size];
                     [pictures setObject:picture forKey:key];
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                         handler(picture);
                     });
                 } else {
                     accessRejected = YES;
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                         handler(picture);
                     });
                 }
                 
                 dispatch_semaphore_signal(pictures_semaphore);;
             }];
         } else {
             accessRejected = YES;
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 handler(picture);
             });
             
             dispatch_semaphore_signal(pictures_semaphore);;
         }
     }];
}

@end
