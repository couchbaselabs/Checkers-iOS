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
    
    NSUInteger game;
    NSUInteger team;
    NSUInteger userTeam;
    NSUInteger userGame;
    NSUInteger people;
    NSUInteger votes;
    
    UIView * infoView;
    UIImageView * userImageView;
    UILabel * peopleLabel;
    UILabel * votesLabel;
    
    NSNumberFormatter * numberFormatter;
}

-(id)initWithHandler:(TeamSelectionHandler)handler;

@property NSUInteger game;
@property NSUInteger team;
@property NSUInteger userTeam;
@property NSUInteger userGame;
@property NSUInteger people;
@property NSUInteger votes;

@end
