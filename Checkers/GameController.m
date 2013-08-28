//
//  GameController.m
//  Checkers
//
//  Created by Wayne Carter on 8/26/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "GameController.h"
#import "Facebook.h"
#import "Twitter.h"
#import <Social/Social.h>
#import <CouchbaseLite/CouchbaseLite.h>

#define kGameDocID @"game-1"

// Subroutine to update a document, with retry on conflicts.
static NSError* updateDoc(CBLDocument* doc, BOOL (^block)(NSMutableDictionary*)) {
    NSError* error;
    do {
        NSMutableDictionary* props = [doc.properties mutableCopy];
        if (!props)
            props = [NSMutableDictionary dictionary];
        if (!block(props)) { // Invoke the callback to update the properties!
            return nil;
        }
        if ([doc putProperties: props error: &error]) {
            return nil; // success
        }
    } while (error.code == 409 && [error.domain isEqualToString: CBLHTTPErrorDomain]);
    return error;
}

@implementation GameController
{
    GameViewController * gameViewController;
    CBLDatabase* database;
    CBLDocument* userDoc, *gameDoc, *voteDoc;
    NSString* userID;
}

-(id)initWithGameViewController:(GameViewController *)theGameViewController
                       database:(CBLDatabase*)theDatabase
{
    if (self = [super init]) {
        database = theDatabase;
        gameViewController = theGameViewController;
        gameViewController.delegate = self;

        // Get or create my unique player ID:
        userID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserID"];
        if (!userID) {
            userID = [[NSUUID UUID] UUIDString];
            [[NSUserDefaults standardUserDefaults] setObject:userID forKey:@"UserID"];
            NSLog(@"Generated user ID '%@'", userID);
        }
        userDoc = database[[NSString stringWithFormat:@"user:%@", userID]];
        if (userDoc.currentRevision == nil) {
            // Create an initial blank user document
            NSError* error;
            if (![userDoc putProperties:@{} error:&error]) {
                NSLog(@"WARNING: Couldn't save user doc '%@': %@", userDoc, error);
            }
        }
        gameViewController.user = [[User alloc] initWithDictionary:userDoc.properties];

        // Load the current game state:
        gameDoc = database[kGameDocID];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateGame:)
                                                     name:kCBLDocumentChangeNotification
                                                   object:gameDoc];
        [self updateGame:nil]; // load current game doc

        // Load my current vote:
        voteDoc = database[[NSString stringWithFormat:@"vote:%@", userID]];
        NSDictionary* vote = voteDoc.properties;
        if (!vote)
            vote = @{};
        gameViewController.vote = [[Vote alloc] initWithDictionary:vote];
    }

    return self;
}

- (void)updateGame:(NSNotification*)n {
    // Update gameViewController.game when we receive data changes from server.
    NSLog(@"** Game document changed: %@", gameDoc.currentRevision);
    Game* game = [[Game alloc] initWithDictionary:gameDoc.properties];
    gameViewController.game = game;
}


-(void)gameViewController:(GameViewController *)theGameViewController
            didSelectTeam:(GameTeam *)team {
    NSError* error = updateDoc(userDoc, ^(NSMutableDictionary *props) {
        props[@"team"] = @(team.number);
        return YES;
    });
    if (error) {
        NSLog(@"WARNING: Couldn't save user doc: %@", error);
    }
}

-(void)gameViewController:(GameViewController *)theGameViewController
         didMakeValidMove:(GameValidMove *)validMove {
    NSError* error = updateDoc(userDoc, ^(NSMutableDictionary *props) {
        props[@"game"] = theGameViewController.game.number;
        props[@"team"] = @(validMove.team);
        props[@"pieces"] = @(validMove.piece);
        props[@"locations"] = validMove.locations;
        return YES;
    });
    if (error) {
        NSLog(@"WARNING: Couldn't save move doc: %@", error);
    }
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
