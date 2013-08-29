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
        youLabel = [[UILabel alloc] init];
        peopleLabel = [[UILabel alloc] init];
        votesLabel = [[UILabel alloc] init];
        
        youLabel.backgroundColor = UIColor.clearColor;
        peopleLabel.backgroundColor = UIColor.clearColor;
        votesLabel.backgroundColor = UIColor.clearColor;
        
        [self addSubview:infoView];
        [infoView addSubview:userImageView];
        [infoView addSubview:youLabel];
        [infoView addSubview:peopleLabel];
        [infoView addSubview:votesLabel];
        
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setGroupingSeparator: [[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator]];
        [numberFormatter setUsesGroupingSeparator:YES];
        [numberFormatter setGroupingSize:3];
        
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]];
    }
    
    return self;
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
    return [peopleLabel.text intValue];
}

-(void)setPeople:(NSUInteger)thePeople {
    peopleLabel.text = [NSString stringWithFormat:@"%d", thePeople];
    [self setNeedsLayout];
}

-(NSUInteger)votes {
    return [votesLabel.text intValue];
}

-(void)setVotes:(NSUInteger)theVotes {
    votesLabel.text = [NSString stringWithFormat:@"%d", theVotes];
    [self setNeedsLayout];
}

-(void)layoutSubviews {
    NSUInteger height = self.bounds.size.height;
    NSUInteger padding = (height > 44 + 32 ? 16 : 8);
    
    infoView.frame = CGRectZero;
    
    if (self.userOnTeam) {
        // Image or "You"
        UIView * userIdentifier;
        NSUInteger pictureSize = MIN(height - (2 * padding), 44);
        UIImage * userPicture = [Facebook pictureWithSize:(pictureSize * 2)];
        if (userPicture) {
            userImageView.frame = CGRectMake(0, 0, pictureSize + 4, pictureSize + 4);
            userImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            userImageView.image = [AppStyle strokeImage:userPicture forTeam:self.team];
            
            userIdentifier = userImageView;
        } else {
            youLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            youLabel.textColor = [AppStyle colorForTeam:self.team];
            youLabel.text = @"You";
            [youLabel sizeToFit];
            
            userIdentifier = youLabel;
            
            if (!Facebook.accessRejected) {
                [Facebook pictureWithSize:(pictureSize * 2) handler:^(UIImage *image) {
                    if (image) {
                        [self setNeedsLayout];
                    }
                }];
            }
        }
        userImageView.hidden = (userIdentifier != userImageView);
        youLabel.hidden = (userIdentifier != youLabel);
        
        // Team
        peopleLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        peopleLabel.textAlignment = NSTextAlignmentLeft;
        peopleLabel.textColor = [AppStyle darkColor];
        peopleLabel.text = [NSString stringWithFormat:@"+ %@ people", [numberFormatter stringFromNumber:[NSNumber numberWithInt:self.people]]];
        [peopleLabel sizeToFit];
        peopleLabel.frame = CGRectMake(8 + userIdentifier.frame.origin.x + userIdentifier.frame.size.width, infoView.center.y - (peopleLabel.frame.size.height / 2), peopleLabel.frame.size.width, peopleLabel.frame.size.height);
    } else {
        // Hide Image and "You"
        userImageView.hidden = YES;
        youLabel.hidden = YES;
        
        // Other team
        peopleLabel.textAlignment = NSTextAlignmentCenter;
        peopleLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        if (self.userCanJoinTeam) {
            peopleLabel.textColor = [AppStyle colorForTeam:self.team];
            peopleLabel.text = [NSString stringWithFormat:@"Join\n%@ people", [numberFormatter stringFromNumber:[NSNumber numberWithInt:self.people]]];
            self.userInteractionEnabled = YES;
        } else {
            peopleLabel.textColor = [AppStyle darkColor];
            peopleLabel.text = [NSString stringWithFormat:@"%@ people", [numberFormatter stringFromNumber:[NSNumber numberWithInt:self.people]]];
            self.userInteractionEnabled = NO;
        }
        [peopleLabel sizeToFit];
        peopleLabel.frame = CGRectMake(0, 0, peopleLabel.frame.size.width, peopleLabel.frame.size.height);
    }
    
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

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    handler(self.team);
}

@end
