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
    self.timeLabel = @"starts in";
    [header addSubview:timeLabel];
    //   Value
    timeValue = [[UILabel alloc] init];
    timeValue.backgroundColor = UIColor.clearColor;
    timeValue.font = [UIFont systemFontOfSize:24];
    timeValue.textColor = AppStyle.darkColor;
    self.timeValue = @"--";
    [header addSubview:timeValue];
    
    // Twitter Button
    twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [twitterButton setImage:[UIImage imageNamed:@"Twitter-Dark.png"] forState:UIControlStateNormal];
    [twitterButton setImage:[UIImage imageNamed:@"Twitter-Dark-Highlighted.png"] forState:UIControlStateHighlighted];
    twitterButton.frame = CGRectMake(width - headerSize, 0, headerSize, headerSize);
    twitterButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    twitterButton.contentMode = UIViewContentModeCenter;
    [twitterButton addTarget:self action:@selector(twitterClick:) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:twitterButton];
    
    // Facebook Button
    facebookButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [facebookButton setImage:[UIImage imageNamed:@"Facebook-Dark.png"] forState:UIControlStateNormal];
    [facebookButton setImage:[UIImage imageNamed:@"Facebook-Dark-Highlighted.png"] forState:UIControlStateHighlighted];
    facebookButton.frame = CGRectMake(twitterButton.frame.origin.x - headerSize, 0, headerSize, headerSize);
    facebookButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    facebookButton.contentMode = UIViewContentModeCenter;
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
    
    team1Info = [[UIView alloc] init];
    [self.view addSubview:team1Info];
    
    team2Info = [[UIView alloc] init];
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
    game = theGame;
    
    [checkerboard setGame:game animated:YES];
    
    [self layoutGameInfo];
    [self layoutTeamInfo];
}

-(Vote *)vote {
    return vote;
}

-(void)setVote:(Vote *)theVote {
    vote = theVote;
    
    [self layoutTeamInfo];
    [self layoutGameInfo];
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
        } else if (![game.activeTeam isEqualToNumber:user.team]) {
            checkerboard.userInteractionEnabled = NO;
        } else if ([game.number isEqualToNumber:vote.game] && [game.number isEqualToNumber:vote.game]) {
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
    
    // TODO: Delete.  For debugging always allow input.
    checkerboard.userInteractionEnabled = YES;
}

- (void)layoutTeamInfo {
    // Clear info.
    [team1Info removeAllSubviews];
    [team2Info removeAllSubviews];
    
    team1Info.frame = CGRectZero;
    team2Info.frame = CGRectZero;
    
    if (!game) {
        return;
    }
    
    int teamInfoSize = checkerboard.frame.origin.y - (header.frame.origin.y + header.frame.size.height);
    int teamInfoPadding = (teamInfoSize > 44 + 32 ? 16 : 8);
    
    // Set facebook image.
    if (user.team) {
        int teamNumber = (user.team.intValue == 1 ? 1 : 0);
        int otherTeamNumber = (user.team.intValue == 1 ? 0 : 1);
        GameTeam * team = [self.game.teams objectAtIndex:teamNumber];
        GameTeam * otherTeam = [self.game.teams objectAtIndex:otherTeamNumber];
        
        UIView * teamInfo = (teamNumber == 1 ? team2Info : team1Info);
        UIView * otherTeamInfo = (otherTeamNumber == 1 ? team2Info : team1Info);
        
        // Image or "You"
        UIView * userIdentifier;
        if (user.facebookId) {
            int imageSize = MIN(teamInfoSize - (2 * teamInfoPadding), 44);
            UIImageView * userImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageSize + 4, imageSize + 4)];
            userImage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            // TODO: We should load asynchronously and probably cache.
            NSURL * imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?width=%d&height=%d", user.facebookId, imageSize * 2, imageSize * 2]];
            
            userImage.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageUrl]];
            userImage.image = [AppStyle strokeImage:userImage.image forTeam:user.team.intValue];
            
            userIdentifier = userImage;
            [teamInfo addSubview:userImage];
        } else {
            UILabel * userLabel = [[UILabel alloc] init];
            userLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            
            userLabel.textColor = [AppStyle colorForTeam:user.team.intValue];
            userLabel.text = @"You";
            [userLabel sizeToFit];
            
            userIdentifier = userLabel;
            [teamInfo addSubview:userLabel];
        }
        
        // Team
        UILabel * people = [[UILabel alloc] init];
        people.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        people.textColor = [AppStyle darkColor];
        NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setGroupingSeparator: [[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator]];
        [numberFormatter setUsesGroupingSeparator:YES];
        [numberFormatter setGroupingSize:3];
        people.text = [NSString stringWithFormat:@"+ %@ people", [numberFormatter stringFromNumber:[NSNumber numberWithInt:team.participantCount]]];
        [people sizeToFit];
        people.frame = CGRectMake(8 + userIdentifier.frame.origin.x + userIdentifier.frame.size.width, teamInfo.center.y - (people.frame.size.height / 2), people.frame.size.width, people.frame.size.height);
        [teamInfo addSubview:people];
        
        // Other team
        UILabel * otherPeople = [[UILabel alloc] init];
        otherPeople.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        otherPeople.numberOfLines = 0;
        otherPeople.textAlignment = NSTextAlignmentCenter;
        if (!vote || ![self.game.number isEqualToNumber:self.vote.game]) {
            otherPeople.tag = otherTeamNumber;
            otherPeople.textColor = [AppStyle colorForTeam:otherTeamNumber];
            otherPeople.text = [NSString stringWithFormat:@"Join\n%@ people", [numberFormatter stringFromNumber:[NSNumber numberWithInt:otherTeam.participantCount]]];
            [otherPeople addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTeamTap:)]];
            otherPeople.userInteractionEnabled = YES;
        } else {
            otherPeople.textColor = [AppStyle darkColor];
            otherPeople.text = [NSString stringWithFormat:@"%@ people", [numberFormatter stringFromNumber:[NSNumber numberWithInt:otherTeam.participantCount]]];
        }
        [otherPeople sizeToFit];
        [otherTeamInfo addSubview:otherPeople];
    } else {
        NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setGroupingSeparator: [[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator]];
        [numberFormatter setUsesGroupingSeparator:YES];
        [numberFormatter setGroupingSize:3];
        
        // Team 1
        GameTeam * team1 = [self.game.teams objectAtIndex:0];
        UILabel * team1People = [[UILabel alloc] init];
        team1People.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        team1People.tag = 0;
        team1People.numberOfLines = 0;
        team1People.textAlignment = NSTextAlignmentCenter;
        team1People.textColor = [AppStyle colorForTeam:0];
        team1People.text = [NSString stringWithFormat:@"Join\n%@ people", [numberFormatter stringFromNumber:[NSNumber numberWithInt:team1.participantCount]]];
        [team1People addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTeamTap:)]];
        team1People.userInteractionEnabled = YES;
        [team1People sizeToFit];
        [team1Info addSubview:team1People];
        
        // Team 2
        GameTeam * team2 = [self.game.teams objectAtIndex:0];
        UILabel * team2People = [[UILabel alloc] init];
        team2People.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        team2People.tag = 1;
        team2People.numberOfLines = 0;
        team2People.textAlignment = NSTextAlignmentCenter;
        team2People.textColor = [AppStyle colorForTeam:1];
        team2People.text = [NSString stringWithFormat:@"Join\n%@ people", [numberFormatter stringFromNumber:[NSNumber numberWithInt:team2.participantCount]]];
        [team2People addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTeamTap:)]];
        team2People.userInteractionEnabled = YES;
        [team2People sizeToFit];
        [team2Info addSubview:team2People];
    }
    
    // Center team info.
    [team1Info sizeToFitSubviews];
    team1Info.frame = CGRectMake(self.view.center.x - (team1Info.frame.size.width / 2),
                                 checkerboard.frame.origin.y - team1Info.frame.size.height - teamInfoPadding,
                                 team1Info.frame.size.width,
                                 team1Info.frame.size.height);
    
    [team2Info sizeToFitSubviews];
    team2Info.frame = CGRectMake(self.view.center.x - (team2Info.frame.size.width / 2),
                                 checkerboard.frame.origin.y + checkerboard.frame.size.height + teamInfoPadding,
                                 team2Info.frame.size.width,
                                 team2Info.frame.size.height);
}

- (void)handleTeamTap:(UITapGestureRecognizer *)recognizer {
    [self.delegate gameViewController:self didSelectTeam:[self.game.teams objectAtIndex:recognizer.view.tag]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

@end
