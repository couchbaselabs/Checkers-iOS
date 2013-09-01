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
    
    NSNumber * game;
    NSNumber * team;
    NSNumber * userTeam;
    NSNumber * userGame;
    NSUInteger people;
    NSUInteger votes;
    
    UIView * infoView;
    UIImageView * userImageView;
    UILabel * peopleLabel;
    UILabel * votesLabel;
    
    NSNumberFormatter * numberFormatter;
}

-(id)initWithHandler:(TeamSelectionHandler)handler;

@property NSNumber * game;
@property NSNumber * team;
@property NSNumber * userTeam;
@property NSNumber * userGame;
@property NSUInteger people;
@property NSUInteger votes;

@end
