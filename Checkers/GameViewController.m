//
//  GameViewController.m
//  Checkers
//
//  Created by Wayne Carter on 8/19/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "GameViewController.h"
#import "AppStyle.h"
#import "Checkerboard.h"
#import "Game.h"
#import "UIView+Extended.h"
#import "Facebook.h"
#import "Twitter.h"
#import <QuartzCore/QuartzCore.h>
#import "NSNumber+Equality.h"

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    float width = self.view.frame.size.width;
    float height = self.view.frame.size.height;
    
    self.view.backgroundColor = AppStyle.lightColor;
    
    // - Header ------------------
    
    // Background
    float headerSize = 44;
    header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, headerSize)];
    header.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    header.backgroundColor = AppStyle.mediumColor;
    [self.view addSubview:header];
    
    // Time Label/Value
    //   Label
    timeLabel = [[UILabel alloc] init];
    timeLabel.backgroundColor = UIColor.clearColor;
    timeLabel.font = [UIFont systemFontOfSize:18];
    timeLabel.textColor = AppStyle.darkColor;
    self.timeLabel = @"waiting for game...";
    [header addSubview:timeLabel];
    //   Value
    timeValue = [[UILabel alloc] init];
    timeValue.backgroundColor = UIColor.clearColor;
    timeValue.font = [UIFont systemFontOfSize:24];
    timeValue.textColor = AppStyle.darkColor;
    [header addSubview:timeValue];
    
    // Twitter Button
    twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [twitterButton setImage:[UIImage imageNamed:@"Twitter-Dark.png"] forState:UIControlStateNormal];
    [twitterButton setImage:[UIImage imageNamed:@"Twitter-Dark-Highlighted.png"] forState:UIControlStateHighlighted];
    twitterButton.frame = CGRectMake(width - headerSize, 0, headerSize, headerSize);
    twitterButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    twitterButton.contentMode = UIViewContentModeCenter;
    twitterButton.hidden = YES;
    [twitterButton addTarget:self action:@selector(twitterClick:) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:twitterButton];
    
    // Facebook Button
    facebookButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [facebookButton setImage:[UIImage imageNamed:@"Facebook-Dark.png"] forState:UIControlStateNormal];
    [facebookButton setImage:[UIImage imageNamed:@"Facebook-Dark-Highlighted.png"] forState:UIControlStateHighlighted];
    facebookButton.frame = CGRectMake(twitterButton.frame.origin.x - headerSize, 0, headerSize, headerSize);
    facebookButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    facebookButton.contentMode = UIViewContentModeCenter;
    facebookButton.hidden = YES;
    [facebookButton addTarget:self action:@selector(facebookClick:) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:facebookButton];
    
    // ---------------------------
    
    // - Checkerboard ------------
    
    checkerboard = [[Checkerboard alloc] initWithFrame:CGRectMake(0, 0, width, width)];
    checkerboard.center = self.view.center;
    checkerboard.delegate = self;
    [self.view addSubview: checkerboard];
    
    // ---------------------------
    
    // - Footer ------------------
    
    // Background
    float footerSize = 44;
    footer = [[UIView alloc] initWithFrame:CGRectMake(0, height - footerSize, width, footerSize)];
    footer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    footer.backgroundColor = AppStyle.mediumColor;
    [self.view addSubview:footer];
    
    // Team 1 Image/Score
    //   Image
    team1ScoreImage = [[UIImageView alloc] initWithImage:[AppStyle pieceForTeam:0 squareSize:footerSize king:NO]];
    [footer addSubview:team1ScoreImage];
    //   Score
    team1Score = [[UILabel alloc] init];
    team1Score.backgroundColor = UIColor.clearColor;
    team1Score.font = [UIFont systemFontOfSize:24];
    team1Score.textColor = AppStyle.darkColor;
    [self setTeam1Score:@"--"];
    [footer addSubview:team1Score];
    
    // Team 2 Image/Score
    //   Image
    team2ScoreImage = [[UIImageView alloc] initWithImage:[AppStyle pieceForTeam:1 squareSize:footerSize king:NO]];
    [footer addSubview:team2ScoreImage];
    //   Score
    team2Score = [[UILabel alloc] init];
    team2Score.backgroundColor = UIColor.clearColor;
    team2Score.font = [UIFont systemFontOfSize:24];
    team2Score.textColor = AppStyle.darkColor;
    [self setTeam2Score:@"--"];
    [footer addSubview:team2Score];
    
    // ---------------------------
    
    // Team Info -----------------
    
    team1Info = [[TeamView alloc] initWithHandler:^(NSUInteger team) {
        [self.delegate gameViewController:self didSelectTeam:[self.game.teams objectAtIndex:team]];
    }];
    [self.view addSubview:team1Info];
    
    team2Info = [[TeamView alloc] initWithHandler:^(NSUInteger team) {
        [self.delegate gameViewController:self didSelectTeam:[self.game.teams objectAtIndex:team]];
    }];
    [self.view addSubview:team2Info];
    
    // ---------------------------
}

-(User *)user {
    return user;
}

-(void)setUser:(User *)theUser {
    user = theUser;
    
    [self layoutTeamInfo];
    [self layoutGameInfo];
}

-(Game *)game {
    return game;
}

-(void)setGame:(Game *)theGame {
    BOOL newWinner = (game && theGame.winningTeam && ![NSNumber number:game.winningTeam isEqualToNumber:theGame.winningTeam]);
    game = theGame;
    
    [checkerboard setGame:game animated:YES];
    
    [self layoutGameInfo];
    [self layoutTeamInfo];
    
    // On new winner...show.
    if (newWinner) {
        int winningTeam = theGame.winningTeam.intValue;
        UILabel * winnerView = [[UILabel alloc] init];
        winnerView.text = (winningTeam == 1 ? @"Blue Wins!" : @"Red Wins!");
        winnerView.font = [UIFont boldSystemFontOfSize:32];
        winnerView.textColor = [AppStyle colorForTeam:winningTeam];
        winnerView.backgroundColor = UIColor.clearColor;
        [winnerView sizeToFit];
        winnerView.center = checkerboard.center;
        [self.view addSubview:winnerView];
        
        float zoom = (self.view.bounds.size.width / winnerView.frame.size.width);
        winnerView.alpha = 0;
        winnerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, zoom, zoom);
        [UIView animateWithDuration: 0.1
                              delay: 0
                            options: (UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction)
                         animations:^{
                             winnerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
                             winnerView.alpha = 1;
                         }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration: 3
                                                   delay: 0
                                                 options: (UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction)
                                              animations:^{
                                                  winnerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.90, 0.90);
                                              }
                                              completion:^(BOOL finished) {
                                                  [UIView animateWithDuration: 0.2
                                                                        delay: 0
                                                                      options: (UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction)
                                                                   animations:^{
                                                                       winnerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, zoom, zoom);
                                                                       winnerView.alpha = 0;
                                                                   }
                                                                   completion:^(BOOL finished) {
                                                                       [winnerView removeFromSuperview];
                                                                   }
                                                   ];
                                              }
                              ];
                         }
         ];
    }
}

-(Vote *)vote {
    return vote;
}

-(void)setVote:(Vote *)theVote {
    vote = theVote;
    
    [self layoutTeamInfo];
    [self layoutGameInfo];
}

-(Votes *)votes {
    return votes;
}

-(void)setVotes:(Votes *)theVotes {
    votes = theVotes;
    checkerboard.votes = theVotes;
}

-(IBAction)facebookClick:(id)sender
{
    [self.delegate gameViewController:self buttonTapped:CBCGameViewControllerButtonFacebook];
}

-(IBAction)twitterClick:(id)sender
{
    [self.delegate gameViewController:self buttonTapped:CBCGameViewControllerButtonTwitter];
}

-(void)checkerboard:(Checkerboard *)checkerboard didMakeValidMove:(GameValidMove *)validMove {
    [self.delegate gameViewController:self didMakeValidMove:validMove];
}

-(void)handleCountdownTimerTick {
    NSTimeInterval secondsRemaining = [countdownTime timeIntervalSinceNow];
    int seconds =  floor(secondsRemaining);
    NSString * milliseconds = [NSString stringWithFormat:@"%.0f", (secondsRemaining - seconds) * 1000];
    
    while (milliseconds.length < 3) {
        milliseconds = [milliseconds stringByAppendingString:@"0"];
    }
    
    if (secondsRemaining > 0) {
        self.timeValue = [NSString stringWithFormat:@"%d:%@", seconds, milliseconds];
    } else {
        [countdownTimer invalidate];
        
        self.timeValue = @"00:000";
        
        [countdownTimeoutTimer invalidate];
        countdownTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(handleCountdownTimeoutTimerTick) userInfo:nil repeats:YES];
        
        [self layoutGameInfo];
    }
}

-(void)handleCountdownTimeoutTimerTick {
    NSTimeInterval secondsRemaining = [countdownTime timeIntervalSinceNow];
    
    if (secondsRemaining <= 0) {
        // Flash time value on timeout.
        timeValue.hidden = !timeValue.hidden;
    } else {
        timeValue.hidden = NO;
    }
}

-(void)setCountdownTime:(NSDate *)theTime {
    [countdownTimer invalidate];
    [countdownTimeoutTimer invalidate];
    
    if (theTime) {
        countdownTime = theTime;
        NSTimeInterval secondsRemaining = [countdownTime timeIntervalSinceNow];
        
        if (secondsRemaining > 0) {
            countdownTimer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(handleCountdownTimerTick) userInfo:nil repeats:YES];
        } else {
            self.timeValue = @"00:000";
            countdownTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(handleCountdownTimeoutTimerTick) userInfo:nil repeats:YES];
        }
    } else {
        self.timeValue = @"--";
    }
}

- (void)setTimeValue:(NSString *)value
{
    timeValue.text = value;
    [timeValue sizeToFit];
    timeValue.frame = CGRectMake(timeLabel.frame.origin.x + timeLabel.frame.size.width + 4,
                                 (header.bounds.size.height / 2) - (timeValue.frame.size.height / 2),
                                 timeValue.frame.size.width,
                                 timeValue.frame.size.height);
}

- (void)setTimeLabel:(NSString *)label
{
    timeLabel.text = label;
    [timeLabel sizeToFit];
    timeLabel.frame = CGRectMake(10,
                                 (header.bounds.size.height / 2) - (timeLabel.frame.size.height / 2),
                                 timeLabel.frame.size.width,
                                 timeLabel.frame.size.height);
    
    // Kick the value so that it repositions itself.
    self.timeValue = timeValue.text;
}

- (void)setTeam1Score:(NSString *)score
{
    team1Score.text = score;
    [team1Score sizeToFit];
    
    float padding = 4;
    team1ScoreImage.frame = CGRectMake((footer.bounds.size.width / 4.0f) - ((team1ScoreImage.frame.size.width + padding + team1Score.frame.size.width) / 2),
                                       (footer.bounds.size.height / 2) - (team1ScoreImage.frame.size.height / 2),
                                       team1ScoreImage.frame.size.width,
                                       team1ScoreImage.frame.size.height);
    
    team1Score.frame = CGRectMake(team1ScoreImage.frame.origin.x + team1ScoreImage.frame.size.width + padding,
                                  (footer.bounds.size.height / 2) - (team1Score.frame.size.height / 2),
                                  team1Score.frame.size.width,
                                  team1Score.frame.size.height);
}

- (void)setTeam2Score:(NSString *)score
{
    team2Score.text = score;
    [team2Score sizeToFit];
    
    float padding = 4;
    team2ScoreImage.frame = CGRectMake(footer.bounds.size.width - (footer.bounds.size.width / 4.0f) - ((team2ScoreImage.frame.size.width + padding + team2Score.frame.size.width) / 2),
                                       (footer.bounds.size.height / 2) - (team2ScoreImage.frame.size.height / 2),
                                       team2ScoreImage.frame.size.width,
                                       team2ScoreImage.frame.size.height);
    
    team2Score.frame = CGRectMake(team2ScoreImage.frame.origin.x + team2ScoreImage.frame.size.width + padding,
                                  (footer.bounds.size.height / 2) - (team2Score.frame.size.height / 2),
                                  team2Score.frame.size.width,
                                  team2Score.frame.size.height);
}

- (void)layoutGameInfo {
    NSTimeInterval secondsUntilStartTime = [game.startTime timeIntervalSinceNow];
    NSTimeInterval secondsUntilMoveDeadline = [game.moveDeadline timeIntervalSinceNow];
    
    if (secondsUntilStartTime <= 0 && game.activeTeam) {
        header.backgroundColor = [AppStyle colorForTeam:game.activeTeam.intValue];
        
        timeLabel.textColor = AppStyle.lightColor;
        timeValue.textColor = AppStyle.lightColor;
        timeValue.hidden = NO;
        
        [twitterButton setImage:[UIImage imageNamed:@"Twitter-Light.png"] forState:UIControlStateNormal];
        [twitterButton setImage:[UIImage imageNamed:@"Twitter-Light-Highlighted.png"] forState:UIControlStateHighlighted];
        
        [facebookButton setImage:[UIImage imageNamed:@"Facebook-Light.png"] forState:UIControlStateNormal];
        [facebookButton setImage:[UIImage imageNamed:@"Facebook-Light-Highlighted.png"] forState:UIControlStateHighlighted];
    } else {
        header.backgroundColor = AppStyle.mediumColor;
        
        timeLabel.textColor = AppStyle.darkColor;
        timeValue.textColor = AppStyle.darkColor;
        timeValue.hidden = NO;
        
        [twitterButton setImage:[UIImage imageNamed:@"Twitter-Dark.png"] forState:UIControlStateNormal];
        [twitterButton setImage:[UIImage imageNamed:@"Twitter-Dark-Highlighted.png"] forState:UIControlStateHighlighted];
        
        [facebookButton setImage:[UIImage imageNamed:@"Facebook-Dark.png"] forState:UIControlStateNormal];
        [facebookButton setImage:[UIImage imageNamed:@"Facebook-Dark-Highlighted.png"] forState:UIControlStateHighlighted];
    }
    
    self.team1Score = [NSNumber numberWithInteger:((GameTeam *)game.teams[0]).score].stringValue;
    self.team2Score = [NSNumber numberWithInteger:((GameTeam *)game.teams[1]).score].stringValue;
    
    if (secondsUntilStartTime <= 0 && game.moveDeadline) {
        self.timeLabel = @"time";
        
        if (secondsUntilMoveDeadline <= 0) {
            checkerboard.userInteractionEnabled = NO;
        } else if (![NSNumber number:game.activeTeam isEqualToNumber:user.team]) {
            checkerboard.userInteractionEnabled = NO;
        } else if (vote && [NSNumber number:game.number isEqualToNumber:vote.game] && [NSNumber number:game.turn isEqualToNumber:vote.turn]) {
            checkerboard.userInteractionEnabled = NO;
        } else {
            checkerboard.userInteractionEnabled = YES;
        }
        
        self.countdownTime = game.moveDeadline;
    } else {
        self.timeLabel = @"starts in";
        
        checkerboard.userInteractionEnabled = NO;
        self.countdownTime = game.startTime;
    }
    
    // Facebook/Twitter compose services.
    twitterButton.hidden = !Twitter.composeServiceAvailable;
    facebookButton.hidden = !Facebook.composeServiceAvailable;
    if (twitterButton.hidden) {
        facebookButton.frame = twitterButton.frame;
    } else {
        facebookButton.frame = CGRectMake(twitterButton.frame.origin.x - facebookButton.frame.size.width,
                                          facebookButton.frame.origin.y,
                                          facebookButton.frame.size.width,
                                          facebookButton.frame.size.height);
    }
}

- (void)layoutTeamInfo {
    team1Info.team = 0;
    team1Info.userOnTeam = (self.user.team && [NSNumber number:self.user.team isEqualToNumber:[NSNumber numberWithInt:0]]);
    team1Info.userCanJoinTeam = (!self.vote || !self.vote.game || ![NSNumber number:self.game.number isEqualToNumber:self.vote.game]);
    team1Info.people = ((GameTeam *)[self.game.teams objectAtIndex:0]).participantCount;
    team1Info.votes = votes.count.integerValue;
    team1Info.frame = CGRectMake(0,
                                 header.frame.origin.y + header.frame.size.height,
                                 self.view.bounds.size.width,
                                 checkerboard.frame.origin.y - (header.frame.origin.y + header.frame.size.height));
    
    team2Info.team = 1;
    team2Info.userOnTeam = (self.user.team && [NSNumber number:self.user.team isEqualToNumber:[NSNumber numberWithInt:1]]);
    team2Info.userCanJoinTeam = (!self.vote || !self.vote.game|| ![NSNumber number:self.game.number isEqualToNumber:self.vote.game]);
    team2Info.people = ((GameTeam *)[self.game.teams objectAtIndex:1]).participantCount;
    team2Info.votes = votes.count.integerValue;
    team2Info.frame = CGRectMake(0,
                                 checkerboard.frame.origin.y + checkerboard.frame.size.height,
                                 self.view.bounds.size.width,
                                 footer.frame.origin.y - (checkerboard.frame.origin.y + checkerboard.frame.size.height));
    // TODO: Votes
}

-(UIImage *)gameAsImage {
    UIView * view = self.view;
    
    // Title Bar
    UIView * titleBar = [[UIView alloc] initWithFrame:header.frame];
    titleBar.backgroundColor = header.backgroundColor;
    
    // Icon
    UIImageView * icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Couch.png"]];
    [titleBar addSubview:icon];
    
    // Title
    UILabel * title = [[UILabel alloc] init];
    title.backgroundColor = timeValue.backgroundColor;
    title.textColor = timeValue.textColor;
    title.text = @"Checkers";
    [title sizeToFit];
    title.frame = CGRectMake(icon.frame.origin.x + icon.frame.size.width,
                             (titleBar.bounds.size.height / 2) - (title.frame.size.height / 2),
                             title.frame.size.width,
                             title.frame.size.height);
    [titleBar addSubview:title];
    
    // Overlay titlebar.
    [view addSubview:titleBar];
    
    // Paint image in current context.
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    // Remove titlebar.
    [titleBar removeFromSuperview];
    
    // Get painted picture.
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

@end
