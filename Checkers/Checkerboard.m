//
//  Checkerboard.m
//  Checkers
//
//  Created by Wayne Carter on 8/19/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "Checkerboard.h"
#import "AppStyle.h"
#import <QuartzCore/QuartzCore.h>

// Piece.
@interface CheckerboardPieceView : UIImageView

@property GamePiece * piece;

@end

@implementation CheckerboardPieceView


@end

// Valid move.
@interface CheckerboardValidMoveView : UIImageView

-(id)initWithImage:(UIImage *)image move:(GameValidMove *)move location:(NSNumber *)location;

@property (readonly) GameValidMove * move;
@property (readonly) NSNumber * location;

@end

@implementation CheckerboardValidMoveView

-(id)initWithImage:(UIImage *)image move:(GameValidMove *)theMove location:(NSNumber *)theLocation {
    if (self = [super initWithImage:image]) {
        _move = theMove;
        _location = theLocation;
    }
    
    return self;
}

@end

// Checkerboard.
@implementation Checkerboard

- (int)size
{
    // Static for now.
    return 8;
}

- (float)squareSize
{
    int size = self.size;
    
    return MIN(self.bounds.size.width / size, self.bounds.size.height / size);
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        allowUserInteraction = true;
        
        int size = self.size;
        float squareSize = self.squareSize;
        
        self.backgroundColor = AppStyle.lightColor;
        
        // Add squares.
        squares = [NSMutableArray array];
        for (int i=0; i<size*size/2; i++) {
            UIView * square = [[UIView alloc] initWithFrame:CGRectMake(0, 0, squareSize, squareSize)];
            square.backgroundColor = AppStyle.mediumColor;
            
            [squares addObject:square];
            [self addSubview:square];
        }
        
        teamPieces = [NSArray arrayWithObjects:[NSMutableArray array], [NSMutableArray array], nil];
        validMoves = [NSMutableArray array];
    }
    
    return self;
}

- (UIView *)squareAtLocation:(NSNumber *)location {
    return [squares objectAtIndex:location.intValue - 1];
}

- (void)clearValidMoves
{
    for (UIView * validMove in validMoves) {
        [validMove removeFromSuperview];
    }
    
    [validMoves removeAllObjects];
}

- (void)addValidMove:(CheckerboardValidMoveView *)validMove {
    // Check to see if there is already a valid move in the same location.
    int existingIndex = NSNotFound;
    for (int i=0; i<validMoves.count; i++) {
        CheckerboardValidMoveView * existingValidMove = [validMoves objectAtIndex:i];
        
        if ([existingValidMove.location isEqualToNumber:validMove.location]) {
            existingIndex = i;
            break;
        }
    }
    
    // Last in wins so if we found another move in the same location then remove it.
    if (existingIndex != NSNotFound) {
        UIView * previousValidMove = [validMoves objectAtIndex:existingIndex];
        
        [validMoves removeObjectAtIndex:existingIndex];
        [previousValidMove removeFromSuperview];
    }
    
    // Add the valid move.
    [validMoves addObject:validMove];
    [self addSubview:validMove];
}

- (void)showValidMovesForPiece:(GamePiece *)piece
{
    [self clearValidMoves];
    
    float squareSize = self.squareSize;
    
    // Sort valid moves decending based on locations count.  This allows partial overlapping moves.
    NSArray * moves = [piece.validMoves sortedArrayUsingComparator:^NSComparisonResult(GameValidMove * validMove1, GameValidMove * validMove2) {
        if (validMove1.locations.count > validMove2.locations.count) {
            return NSOrderedAscending;
        } else if (validMove1.locations.count < validMove2.locations.count) {
            return NSOrderedDescending;
        }
        
        return NSOrderedSame;
    }];
    
    for (GameValidMove * move in moves) {
        if (move.locations.count > 0) {
            UIView * square = [self squareAtLocation:piece.location];
            
            CheckerboardValidMoveView * validMove = [[CheckerboardValidMoveView alloc] initWithImage:[AppStyle validMoveForTeam:piece.team squareSize:squareSize] move:nil location:piece.location];
            validMove.center = square.center;
            [self addValidMove:validMove];
            
            for (NSNumber * location in move.locations) {
                UIView * square = [self squareAtLocation:location];
                UIImage * validMoveImage = [AppStyle validMoveForTeam:piece.team squareSize:squareSize];
                validMove = [[CheckerboardValidMoveView alloc] initWithImage:validMoveImage move:move location:location];
                validMove.userInteractionEnabled = YES;
                validMove.center = square.center;
                
                UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleValidMoveTap:)];
                [validMove addGestureRecognizer:tapRecognizer];
                
                [self addValidMove:validMove];
            }
        }
    }
}

- (void)handlePieceTap:(UITapGestureRecognizer *)recognizer {
    if (!self.userInteractionEnabled) return;
    
    [self showValidMovesForPiece:((CheckerboardPieceView *)recognizer.view).piece];
}

- (void)executeValidMove:(GameValidMove *)validMove {
    GamePiece * piece = [((GameTeam *)[game.teams objectAtIndex:validMove.team]).pieces objectAtIndex:validMove.piece];
    
    // Add move to game moves.
    NSMutableArray * locations = [NSMutableArray arrayWithArray:validMove.locations];
    [locations insertObject:piece.location atIndex:0];
    [game.moves addObject:[[GameMove alloc] initWithTeam:validMove.team piece:validMove.piece locations:locations]];
    
    // Move piece.
    piece.location = [validMove.locations lastObject];
    
    // Remove valid moves from all pieces (i.e. after a move there are no valid moves).
    for (GameTeam * team in game.teams) {
        for (GamePiece * piece in team.pieces) {
            [piece.validMoves removeAllObjects];
        }
    }
    
    // Capture pieces.
    for (GameCapture * capture in validMove.captures) {
        ((GamePiece *)[((GameTeam *)[game.teams objectAtIndex:capture.team]).pieces objectAtIndex:capture.piece]).captured = YES;
    }
    
    // King the piece.
    if (validMove.king && !piece.king) {
        piece.king = YES;
        
        CheckerboardPieceView * pieceView = [((NSArray *)[teamPieces objectAtIndex:validMove.team]) objectAtIndex:validMove.piece];
        pieceView.image = [AppStyle pieceForTeam:validMove.team squareSize:self.squareSize king:YES];
    }
    
    // Set the new game state.
    [self setGame:game animated:YES];
    
    [self.delegate checkerboard:self didMakeValidMove:validMove];
}

- (void)handleValidMoveTap:(UITapGestureRecognizer *)recognizer {
    if (!self.userInteractionEnabled) return;
    
    [self executeValidMove:((CheckerboardValidMoveView *)recognizer.view).move];
}

-(void)setUserInteractionEnabled:(BOOL)userInteractionEnabled {
    super.userInteractionEnabled = userInteractionEnabled;
    
    if (!userInteractionEnabled) {
        [self clearValidMoves];
    }
}

- (Game *)game {
    return game;
}

- (void)setGame:(Game *)theGame {
    [self setGame:theGame animated:NO];
}

- (void)setGame:(Game *)theGame animated:(BOOL)animated {
    [self clearValidMoves];
    
    // Clear the game on nil data.
    if (theGame == nil) {
        for (NSMutableArray * pieces in teamPieces) {
            for (UIView * piece in pieces) {
                [piece removeFromSuperview];
            }
            
            [pieces removeAllObjects];
        }
        
        game = nil;
        return;
    }
    
    GameMove * lastMove = theGame.moves.lastObject;
    BOOL animateLastMove = (animated && [game.number isEqualToNumber:theGame.number] && lastMove.locations.count > 0 ? YES : NO);
    game = theGame;
    
    float squareSize = self.squareSize;
    
    // Set team pieces.
    for (int team=0; team<2; team++) {
        NSArray * pieces = ((GameTeam *)[game.teams objectAtIndex:team]).pieces;
        NSMutableArray * pieceViews = [teamPieces objectAtIndex:team];
        
        for (int i=0; i<pieces.count; i++) {
            GamePiece * piece = [pieces objectAtIndex:i];
            UIView * square = [self squareAtLocation:piece.location];
            
            CheckerboardPieceView * pieceView = (pieceViews.count > i ? [pieceViews objectAtIndex:i] : nil);
            if (pieceView == nil) {
                pieceView = [[CheckerboardPieceView alloc] initWithImage:[AppStyle pieceForTeam:team squareSize:squareSize king:piece.king]];
                pieceView.center = square.center;
                pieceView.alpha = 0;
                
                UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePieceTap:)];
                [pieceView addGestureRecognizer:tapRecognizer];
                
                [pieceViews addObject:pieceView];
                [self addSubview:pieceView];
            }
            
            pieceView.image = [AppStyle pieceForTeam:team squareSize:squareSize king:piece.king];
            pieceView.userInteractionEnabled = (piece.validMoves.count > 0);
            pieceView.piece = piece;
            
            if (!animateLastMove || lastMove.team != team || lastMove.piece != i) {
                if (animated) {
                    [UIView animateWithDuration:0.15 animations:^{
                        pieceView.center = square.center;
                        pieceView.alpha = (piece.captured ? 0 : 1);
                    }];
                } else {
                    pieceView.center = square.center;
                    pieceView.alpha = (piece.captured ? 0 : 1);
                }
            }
        }
    }
    
    // Animate last move.
    if (animateLastMove) {
        NSMutableArray * pieceViews = [teamPieces objectAtIndex:lastMove.team];
        
        if (pieceViews.count > lastMove.piece) {
            GamePiece * piece = [((GameTeam *)[game.teams objectAtIndex:lastMove.team]).pieces objectAtIndex:lastMove.piece];
            UIImageView * pieceView = [pieceViews objectAtIndex:lastMove.piece];
            UIView * finalSquare = [self squareAtLocation:lastMove.locations.lastObject];
            
            if (!CGPointEqualToPoint(pieceView.center, finalSquare.center)) {
                // If we are not already at the final location then we animate along
                // the move's full path.
                
                UIBezierPath * path = [UIBezierPath bezierPath];
                
                NSArray * locations = lastMove.locations;
                for (int i=0; i<locations.count; i++) {
                    NSNumber * location = [locations objectAtIndex:i];
                    UIView * square = [self squareAtLocation:location];
                    
                    if (i == 0) {
                        [path moveToPoint:square.center];
                    } else {
                        [path addLineToPoint:square.center];
                    }
                }
                
                CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
                animation.path = path.CGPath;
                animation.duration = (0.1 * locations.count);
                
                pieceView.layer.position = [path currentPoint];
                pieceView.alpha = (piece.captured ? 0 : 1);
                
                [pieceView.layer addAnimation:animation forKey:nil];
            } else {
                // Otherwise we just flash the piece to indicate the move is confirmed.
                
                pieceView.center = finalSquare.center;
                pieceView.alpha = (piece.captured ? 0 : 1);
                
                if (!piece.captured) {
                    UIImageView * confirmMoveImageView = [[UIImageView alloc] initWithImage:[AppStyle validMoveForTeam:lastMove.team squareSize:squareSize]];
                    confirmMoveImageView.center = pieceView.center;
                    [self addSubview:confirmMoveImageView];
                    
                    // Show, hide, show, hide...remove.
                    confirmMoveImageView.alpha = 1.0f;
                    [UIView animateWithDuration:0 delay:0.25f options:0
                                     animations:^{
                                         confirmMoveImageView.alpha = 0.0f;
                                     }
                                     completion:^(BOOL finished){
                                         [UIView animateWithDuration:0 delay:0.25f options:0
                                                          animations:^{
                                                              confirmMoveImageView.alpha = 1.0f;
                                                          }
                                                          completion:^(BOOL finished){
                                                              [UIView animateWithDuration:0 delay:0.15f options:0
                                                                               animations:^{
                                                                                   confirmMoveImageView.alpha = 0.0f;
                                                                               }
                                                                               completion:^(BOOL finished){
                                                                                   [confirmMoveImageView removeFromSuperview];
                                                                               }];
                                                          }];
                                     }];
                }
            }
        }
    }
}

- (void)layoutSubviews {
    int size = self.size;
    float squareSize = self.squareSize;
    
    for (int i=0; i<squares.count; i++) {
        UIView * square = [self squareAtLocation:[NSNumber numberWithInt:i+1]];
        
        int x = (i % (size / 2)) * 2;
        int y = floor(i / (size / 2));
        
        if (y % 2 == 0) {
            x++;
        }
        
        square.frame = CGRectMake(x * squareSize, y * squareSize, squareSize, squareSize);
    }
}

@end
