//
//  TeamView.m
//  Checkers
//
//  Created by Wayne Carter on 8/28/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "TeamView.h"
#import "Facebook.h"
#import "AppStyle.h"
#import "UIView+Extended.h"

@implementation TeamView

-(id)initWithHandler:(TeamSelectionHandler)theHandler {
    if (self = [super init]) {
        handler = theHandler;
        
        infoView = [[UIView alloc] init];
        userImageView = [[UIImageView alloc] init];
        peopleLabel = [[UILabel alloc] init];
        votesLabel = [[UILabel alloc] init];
        
        peopleLabel.backgroundColor = UIColor.clearColor;
        votesLabel.backgroundColor = UIColor.clearColor;
        
        infoView.userInteractionEnabled = NO;
        
        [self addSubview:infoView];
        [infoView addSubview:userImageView];
        [infoView addSubview:peopleLabel];
        [infoView addSubview:votesLabel];
        
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setGroupingSeparator: [[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator]];
        [numberFormatter setUsesGroupingSeparator:YES];
        [numberFormatter setGroupingSize:3];
        
        [self addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchDragExit];
        [self addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDragEnter];
        [self addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpOutside];
        [self addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return self;
}

-(IBAction)touchDown:(id)sender
{
    self.backgroundColor = RGBA(0, 0, 0, 0.025);
}

-(IBAction)touchUp:(id)sender
{
    self.backgroundColor = nil;
}

-(IBAction)click:(id)sender
{
    [self touchUp:sender];
    handler(self.team);
}

-(NSUInteger)team {
    return team;
}

-(void)setTeam:(NSUInteger)theTeam {
    team = theTeam;
    [self setNeedsLayout];
}

-(BOOL)userOnTeam {
    return userOnTeam;
}

-(void)setUserOnTeam:(BOOL)theUserOnTeam {
    userOnTeam = theUserOnTeam;
    [self setNeedsLayout];
}

-(BOOL)userCanJoinTeam {
    return userCanJoinTeam;
}

-(void)setUserCanJoinTeam:(BOOL)theUserCanJoinTeam {
    userCanJoinTeam = theUserCanJoinTeam;
    [self setNeedsLayout];
}

-(NSUInteger)people {
    return people;
}

-(void)setPeople:(NSUInteger)thePeople {
    people = thePeople;
    [self setNeedsLayout];
}

-(NSUInteger)votes {
    return votes;
}

-(void)setVotes:(NSUInteger)theVotes {
    votes = theVotes;
    [self setNeedsLayout];
}

-(void)layoutSubviews {
    NSUInteger height = self.bounds.size.height;
    NSUInteger padding = (height > 44 + 32 ? 16 : 8);
    
    infoView.frame = CGRectZero;
    
    if (self.userOnTeam) {
        // Image or "You"
        NSUInteger pictureSize = MIN(height - (2 * padding), 44);
        UIImage * userPicture = [Facebook pictureWithSize:(pictureSize * 2)];
        if (userPicture) {
            userImageView.hidden = NO;
            userImageView.frame = CGRectMake(0, 0, pictureSize + 4, pictureSize + 4);
            userImageView.image = [AppStyle strokeImage:userPicture forTeam:self.team];
            
            peopleLabel.text = [NSString stringWithFormat:@" + %@ people", [numberFormatter stringFromNumber:[NSNumber numberWithInt:self.people]]];
            
            peopleLabel.textAlignment = NSTextAlignmentLeft;
            peopleLabel.textColor = AppStyle.darkColor;
            [peopleLabel sizeToFit];
            peopleLabel.frame = CGRectMake(userImageView.frame.size.width, ceil(userImageView.center.y - (peopleLabel.frame.size.height / 2)), peopleLabel.frame.size.width, peopleLabel.frame.size.height);
        } else {
            userImageView.hidden = YES;
            
            NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"You + %@ people", [numberFormatter stringFromNumber:[NSNumber numberWithInt:self.people]]]];
            [text addAttribute: NSForegroundColorAttributeName value:[AppStyle colorForTeam:self.team] range: NSMakeRange(0, 3)];
            [text addAttribute: NSForegroundColorAttributeName value:AppStyle.darkColor range: NSMakeRange(3, text.length - 3)];
            peopleLabel.attributedText = text;
            
            peopleLabel.textAlignment = NSTextAlignmentLeft;
            [peopleLabel sizeToFit];
            peopleLabel.frame = CGRectMake(0, 0, peopleLabel.frame.size.width, peopleLabel.frame.size.height);
            
            // Try to load image from Facebook.
            if (!Facebook.accessRejected) {
                [Facebook pictureWithSize:(pictureSize * 2) handler:^(UIImage *image) {
                    if (image) {
                        [self setNeedsLayout];
                    }
                }];
            }
        }
    } else {
        // Hide Image
        userImageView.hidden = YES;
        
        // Other team
        peopleLabel.textAlignment = NSTextAlignmentCenter;
        if (self.userCanJoinTeam) {
            peopleLabel.textColor = [AppStyle colorForTeam:self.team];
            peopleLabel.text = [NSString stringWithFormat:@"Join\n%@ people", [numberFormatter stringFromNumber:[NSNumber numberWithInt:self.people]]];
        } else {
            peopleLabel.textColor = AppStyle.darkColor;
            peopleLabel.text = [NSString stringWithFormat:@"%@ people", [numberFormatter stringFromNumber:[NSNumber numberWithInt:self.people]]];
        }
        [peopleLabel sizeToFit];
        peopleLabel.frame = CGRectMake(0, 0, peopleLabel.frame.size.width, peopleLabel.frame.size.height);
    }
    
    self.userInteractionEnabled = (!self.userOnTeam && self.userCanJoinTeam);
    
    [infoView sizeToFitSubviews];
    int infoViewPadding = (self.frame.size.height > 44 + 32 ? 16 : 8);
    if (team == 1) {
        infoView.frame = CGRectMake((self.bounds.size.width / 2) - (infoView.frame.size.width / 2),
                                    infoViewPadding,
                                    infoView.frame.size.width,
                                    infoView.frame.size.height);
    } else {
        infoView.frame = CGRectMake((self.bounds.size.width / 2) - (infoView.frame.size.width / 2),
                                    self.bounds.size.height - infoViewPadding - infoView.frame.size.height,
                                    infoView.frame.size.width,
                                    infoView.frame.size.height);
    }
}

@end
