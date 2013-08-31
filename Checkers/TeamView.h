//
//  TeamView.h
//  Checkers
//
//  Created by Wayne Carter on 8/28/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^TeamSelectionHandler)(NSUInteger team);

@interface TeamView : UIButton {
@private
    TeamSelectionHandler handler;
    
    NSUInteger team;
    BOOL userOnTeam;
    BOOL userCanJoinTeam;
    NSUInteger people;
    NSUInteger votes;
    
    UIView * infoView;
    UIImageView * userImageView;
    UILabel * peopleLabel;
    UILabel * votesLabel;
    
    NSNumberFormatter * numberFormatter;
}

-(id)initWithHandler:(TeamSelectionHandler)handler;

@property NSUInteger team;
@property BOOL userOnTeam;
@property BOOL userCanJoinTeam;
@property NSUInteger people;
@property NSUInteger votes;

@end
