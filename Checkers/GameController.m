//
//  GameController.m
//  Checkers
//
//  Created by Wayne Carter on 8/26/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "GameController.h"
#import <Social/Social.h>
#import "Facebook.h"
#import "Twitter.h"

@implementation GameController

-(id)initWithGameViewController:(GameViewController *)theGameViewController {
    if (self = [super init]) {
        gameViewController = theGameViewController;
        gameViewController.delegate = self;
        
        // TODO: Get/load latest user, game, and vote.
        gameViewController.user = [[User alloc] initWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"User-1" ofType:@"json"]]];
        gameViewController.game = [[Game alloc] initWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Game-1" ofType:@"json"]]];
        gameViewController.vote = [[Vote alloc] initWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Vote-1" ofType:@"json"]]];
    }
    
    return self;
}

// TODO: Update gameViewController.game when we receive data changes from server.

-(void)gameViewController:(GameViewController *)theGameViewController didSelectTeam:(GameTeam *)team {
    // TODO: Commit team selection for:
    //
    //        team: team.number
}

-(void)gameViewController:(GameViewController *)theGameViewController didMakeValidMove:(GameValidMove *)validMove {
    // TODO: Commit valid move for:
    //
    //        game: theGameViewController.game.number
    //        team: validMove.team
    //       piece: validMove.piece
    //   locations: validMove.locations
}

-(void)gameViewController:(GameViewController *)theGameViewController buttonTapped:(GameViewControllerButton)button {
    if (button == CBCGameViewControllerButtonFacebook) {
        if (Facebook.composeServiceAvailable)
        {
            SLComposeViewController * sheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            [sheet setInitialText:@"Couchbase Checkers\n\n"];
            
            [sheet addImage:gameViewController.gameAsImage];
            [sheet addURL:[NSURL URLWithString:@"http://www.couchbase.com/checkers"]];
            
            [gameViewController presentViewController:sheet animated:YES completion:nil];
        }
    } else if (button == CBCGameViewControllerButtonTwitter) {
        if (Twitter.composeServiceAvailable)
        {
            SLComposeViewController * sheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            //[sheet setInitialText:@"Couchbase Checkers\n\n"];
            
            [sheet addImage:gameViewController.gameAsImage];
            [sheet addURL:[NSURL URLWithString:@"http://www.couchbase.com/checkers"]];
            
            [gameViewController presentViewController:sheet animated:YES completion:nil];
        }
    }
}

@end
