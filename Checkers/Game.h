//
//  Game.h
//  Checkers
//
//  Created by Wayne Carter on 8/20/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import <Foundation/Foundation.h>

// Team
@interface GameTeam : NSObject {
@protected
    NSMutableDictionary * data;
@private
    NSArray * pieces;
}

-(id)initWithData:(NSDictionary *)theData number:(int)number;

@property (readonly) int number;
@property (readonly) int participantCount;
@property (readonly) NSArray * pieces;
@property (readonly) int score;

@end

// Piece
@interface GamePiece : NSObject {
@protected
    NSMutableDictionary * data;
@private
    NSMutableArray * validMoves;
}

-(id)initWithData:(NSDictionary *)theData number:(int)number team:(int)team;

@property (readonly) int number;
@property (readonly) int team;
@property NSNumber * location;
@property (readonly) NSMutableArray * validMoves;
@property BOOL captured;
@property BOOL king;

@end

// Capture
@interface GameCapture : NSObject {
@protected
    NSMutableDictionary * data;
}

- (id)initWithData:(NSDictionary *)data;

@property (readonly) int team;
@property (readonly) int piece;

@end

// Move
@interface GameMove : NSObject {
@protected
    NSMutableDictionary * data;
}

- (id)initWithData:(NSDictionary *)data;
- (id)initWithTeam:(int)team piece:(int)piece locations:(NSArray *)locations;

@property (readonly) int team;
@property (readonly) int piece;
@property (readonly) NSArray * locations;

@end

// Valid Move
@interface GameValidMove : GameMove {
@private
    NSMutableArray * captures;
}

- (id)initWithData:(NSDictionary *)data team:(int)team piece:(int)piece;

@property (readonly) NSArray * captures;
@property (readonly) BOOL king;

@end

// Game
@interface Game : NSObject {
@protected
    NSMutableDictionary * data;
@private
    NSDate * startTime;
    NSDate * moveDeadline;
    NSMutableArray * moves;
    NSArray * teams;
}

- (id)initWithData:(NSData *)data;
- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (readonly) NSNumber * number;
@property (readonly) NSDate * startTime;
@property (readonly) NSDate * moveDeadline;
@property (readonly) NSNumber * turn;
@property (readonly) NSNumber * activeTeam;
@property (readonly) NSNumber * winningTeam;
@property (readonly) NSMutableArray * moves;
@property (readonly) NSArray * teams;
@property (readonly) BOOL revotingAllowed;

@end
