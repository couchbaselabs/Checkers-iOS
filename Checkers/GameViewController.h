//
//  GameViewController.h
//  Checkers
//
//  Created by Wayne Carter on 8/19/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "Vote.h"
#import "Votes.h"
#import "Checkerboard.h"
#import "TeamView.h"

typedef NS_ENUM(NSInteger, GameViewControllerButton) {
    CBCGameViewControllerButtonFacebook,
    CBCGameViewControllerButtonTwitter
};

@protocol GameViewControllerDelegate;

@interface GameViewController : UIViewController<CheckerboardDelegate> {
@private
    // Data
    User * user;
    Game * game;
    Vote * vote;
    Votes * votes;
    
    // Header
    UIView * header;
    UILabel * timeLabel;
    UILabel * timeValue;
    UIButton * twitterButton;
    UIButton * facebookButton;
    
    // Footer
    UIView * footer;
    UILabel * team1Score;
    UIImageView * team1ScoreImage;
    UILabel * team2Score;
    UIImageView * team2ScoreImage;
    
    // Checkboard
    Checkerboard * checkerboard;
    
    // Time
    NSDate * countdownTime;
    NSTimer * countdownTimer;
    NSTimer * countdownTimeoutTimer;
    
    // Team Info
    TeamView * team1Info;
    TeamView * team2Info;
}

@property id<GameViewControllerDelegate> delegate;
@property User * user;
@property Game * game;
@property Vote * vote;
@property Votes * votes;

-(UIImage *)gameAsImage;

@end

@protocol GameViewControllerDelegate <NSObject>

-(void)gameViewController:(GameViewController *)gameViewController didSelectTeam:(GameTeam *)team;
-(void)gameViewController:(GameViewController *)gameViewController didMakeValidMove:(GameValidMove *)validMove;
-(void)gameViewController:(GameViewController *)gameViewController buttonTapped:(GameViewControllerButton)button;

@end
