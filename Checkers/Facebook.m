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

NSMutableDictionary * pictures;
+(void)pictureWithSize:(int)size handler:(FacebookPictureHandler)handler
{
    if (pictures == nil) {
        pictures = [[NSMutableDictionary alloc] init];
    }
    
    NSNumber * key = [NSNumber numberWithInt:size];
    UIImage * picture = [pictures objectForKey:key];
    if (picture) {
        handler(picture);
        return;
    }
    
    // TODO: Delete. Until I get this tested I'm checking in a static grab of my pic.
    NSURL * pictureUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=%d&height=%d", @"wayneacarter", size, size]];
    picture = [UIImage imageWithData:[NSData dataWithContentsOfURL:pictureUrl]];
    [pictures setObject:picture forKey:key];
    handler(picture);
    return;
    
    ACAccountType * accountType = [Facebook.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    NSDictionary * options = @{ACFacebookAppIdKey: @"581783778545478"};
    
    [accountStore requestAccessToAccountsWithType:accountType options:options completion:
     ^(BOOL granted, NSError *e) {
         if (granted) {
             NSArray * accounts = [Facebook.accountStore accountsWithAccountType:accountType];
             ACAccount * account = [accounts lastObject];
             
             NSURL * url = [NSURL URLWithString:@"https://graph.facebook.com/me"];
             SLRequest * request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodGET URL:url parameters:nil];
             
             request.account = account;
             [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                 if (responseData) {
                     NSDictionary * data = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
                     NSString * userId = data[@"id"];
                     NSURL * pictureUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=%d&height=%d", userId, size, size]];
                     UIImage * picture = [UIImage imageWithData:[NSData dataWithContentsOfURL:pictureUrl]];
                     
                     if (picture) {
                         [pictures setObject:picture forKey:key];
                         
                         dispatch_async(dispatch_get_main_queue(), ^{
                             handler(picture);
                         });
                         
                         return;
                     }
                 }
             }];
         }
         
         handler(nil);
     }];
}

@end
