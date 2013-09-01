//
//  Checkerboard.h
//  Checkers
//
//  Created by Wayne Carter on 8/19/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Game.h"
#import "Vote.h"
#import "Votes.h"

@protocol CheckerboardDelegate;

@interface Checkerboard : UIView {
@private
    NSMutableArray * squares;
    NSArray * teamPieces;
    NSMutableArray * validMoves;
    NSMutableArray * voteMoves;
    NSMutableArray * voteCaptures;
    NSMutableArray * votesViews;
    
    Game * game;
    Vote * vote;
    Votes * votes;
}

-(void)setGame:(Game *)game animated:(BOOL)animated;

@property id<CheckerboardDelegate> delegate;
@property Game * game;
@property Vote * vote;
@property Votes * votes;

@end

@protocol CheckerboardDelegate <NSObject>

-(void)checkerboard:(Checkerboard *)checkerboard didMakeValidMove:(GameValidMove *)validMove;

@end
