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
#import "NSNumber+Equality.h"

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
        highlightsForPiecesWithValidMoves = [NSMutableArray array];
        validMoves = [NSMutableArray array];
        voteMoves = [NSMutableArray array];
        voteCaptures = [NSMutableArray array];
        votesViews = [NSMutableArray array];
    }
    
    return self;
}

- (UIView *)squareAtLocation:(NSNumber *)location {
    if (location) {
        int index = location.intValue - 1;
        
        if (index < squares.count) {
            return [squares objectAtIndex:index];
        }
    }
    
    return nil;
}

- (CheckerboardPieceView *)viewForPiece:(int)piece team:(int)team {
    if (teamPieces.count > team) {
        NSArray * pieces = [teamPieces objectAtIndex:team];
        
        if (pieces.count > piece) {
            return [pieces objectAtIndex:piece];
        }
    }
    
    return nil;
}

- (void)clearHighlightsForPiecesWithValidMoves
{
    for (UIView * validMove in highlightsForPiecesWithValidMoves) {
        [validMove removeFromSuperview];
    }
    
    [highlightsForPiecesWithValidMoves removeAllObjects];
}

- (void)addHighlightForPieceWithValidMoves:(CheckerboardPieceView *)highlightForPieceWithValidMoves
{
    [highlightsForPiecesWithValidMoves addObject:highlightForPieceWithValidMoves];
    [self addSubview:highlightForPieceWithValidMoves];
    [self ensureVotesAtFront];
}

- (void)showHighlightsForPiecesWithValidMoves
{
    if (!game.highlightPiecesWithMoves) return;
    
    [self clearHighlightsForPiecesWithValidMoves];
    [self clearValidMoves];
    
    float squareSize = self.squareSize;
    
    for (GameTeam * team in game.teams) {
        for (GamePiece * piece in team.pieces) {
            BOOL hasValidMoves = NO;
            
            for (GameValidMove * move in piece.validMoves) {
                if (move.locations.count > 0) {
                    for (NSNumber * location in move.locations) {
                        // Only move locations that are not at the piece's current location are actionable.
                        if (![NSNumber number:location isEqualToNumber:piece.location]) {
                            hasValidMoves = YES;
                            break;
                        }
                    }
                    
                    if (hasValidMoves) break;
                }
            }
            
            if (hasValidMoves) {
                UIView * square = [self squareAtLocation:piece.location];
                UIImage * pieceHighlightImage = [AppStyle pieceHighlightForTeam:piece.team squareSize:squareSize];
                CheckerboardPieceView * pieceHighlight = [[CheckerboardPieceView alloc] initWithImage:pieceHighlightImage];
                pieceHighlight.piece = piece;
                pieceHighlight.center = square.center;
                
                [self addHighlightForPieceWithValidMoves:pieceHighlight];
            }
        }
    }
}

- (void)clearValidMoves
{
    for (UIView * validMove in validMoves) {
        [validMove removeFromSuperview];
    }
    
    [validMoves removeAllObjects];
}

- (void)addValidMove:(CheckerboardValidMoveView *)validMove
{
    // Check to see if there is already a valid move in the same location.
    int existingIndex = (int)NSNotFound;
    for (int i=0; i<validMoves.count; i++) {
        CheckerboardValidMoveView * existingValidMove = [validMoves objectAtIndex:i];
        
        if ([NSNumber number:existingValidMove.location isEqualToNumber:validMove.location]) {
            existingIndex = i;
            break;
        }
    }
    
    // Last in wins so if we found another move in the same location then remove it.
    if (existingIndex != (int)NSNotFound) {
        UIView * previousValidMove = [validMoves objectAtIndex:existingIndex];
        
        [validMoves removeObjectAtIndex:existingIndex];
        [previousValidMove removeFromSuperview];
    }
    
    // Add the valid move.
    [validMoves addObject:validMove];
    [self addSubview:validMove];
    [self ensureVotesAtFront];
}

- (void)showValidMovesForPiece:(GamePiece *)piece
{
    // Don't continue if there are no valid moves for the piece.
    if (piece.validMoves.count == 0) return;
    
    [self clearValidMoves];
    [self clearHighlightsForPiecesWithValidMoves];
    
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
            for (NSNumber * location in move.locations) {
                UIView * square = [self squareAtLocation:location];
                UIImage * validMoveImage = [AppStyle pieceHighlightForTeam:piece.team squareSize:squareSize];
                CheckerboardValidMoveView * validMove = [[CheckerboardValidMoveView alloc] initWithImage:validMoveImage move:move location:location];
                validMove.center = square.center;
                
                validMove.userInteractionEnabled = YES;
                UITapGestureRecognizer * tapRecognizer;
                if ([NSNumber number:location isEqualToNumber:piece.location]) {
                    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePieceHighlightTap:)];
                    
                } else {
                    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleValidMoveTap:)];
                }
                [validMove addGestureRecognizer:tapRecognizer];
                
                [self addValidMove:validMove];
            }
        }
    }
}

- (void)handlePieceTap:(UITapGestureRecognizer *)recognizer {
    [self showValidMovesForPiece:((CheckerboardPieceView *)recognizer.view).piece];
}

- (void)handlePieceHighlightTap:(UITapGestureRecognizer *)recognizer {
    [self showHighlightsForPiecesWithValidMoves];
}

- (void)handleValidMoveTap:(UITapGestureRecognizer *)recognizer {
    [self clearValidMoves];
    [self.delegate checkerboard:self didMakeValidMove:((CheckerboardValidMoveView *)recognizer.view).move];
}

-(void)setUserInteractionEnabled:(BOOL)userInteractionEnabled {
    super.userInteractionEnabled = userInteractionEnabled;
    
    if (!userInteractionEnabled) {
        [self clearHighlightsForPiecesWithValidMoves];
        [self clearValidMoves];
    } else {
        [self showHighlightsForPiecesWithValidMoves];
    }
}

- (Game *)game {
    return game;
}

- (void)setGame:(Game *)theGame {
    [self setGame:theGame animated:NO];
}

- (void)setGame:(Game *)theGame animated:(BOOL)animated {
    GameMove * animatedMove;
    GameMove * lastMove = theGame.moves.lastObject;
    if (animated
        && [NSNumber number:game.number isEqualToNumber:theGame.number]
        && ![NSNumber number:game.turn isEqualToNumber:theGame.turn]
        && lastMove.locations.count > 0 ? YES : NO) {
        
        animatedMove = lastMove;
    }
    
    [self setGame:theGame animated:animated animatedMove:animatedMove];
}

- (void)setGame:(Game *)theGame animated:(BOOL)animated animatedMove:(GameMove *)animatedMove {
    [self clearHighlightsForPiecesWithValidMoves];
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
    
    game = theGame;
    
    [self layoutGameAnimated:animated animatedMove:animatedMove];
}

- (void)layoutGameAnimated:(BOOL)animated animatedMove:(GameMove *)animatedMove {
    float squareSize = self.squareSize;
    
    // Set team pieces.
    for (int team=0; team<2; team++) {
        NSArray * pieces = ((GameTeam *)[game.teams objectAtIndex:team]).pieces;
        NSMutableArray * pieceViews = [teamPieces objectAtIndex:team];
        
        for (int i=0; i<pieces.count; i++) {
            GamePiece * piece = [pieces objectAtIndex:i];
            UIView * square = [self squareAtLocation:piece.location];
            
            CheckerboardPieceView * pieceView = [self viewForPiece:i team:team];
            if (pieceView == nil) {
                pieceView = [[CheckerboardPieceView alloc] initWithImage:[AppStyle pieceForTeam:team squareSize:squareSize king:piece.king]];
                pieceView.center = square.center;
                pieceView.alpha = 0;
                
                UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePieceTap:)];
                [pieceView addGestureRecognizer:tapRecognizer];
                pieceView.userInteractionEnabled = YES;
                
                [pieceViews addObject:pieceView];
                [self addSubview:pieceView];
            }
            
            pieceView.image = [AppStyle pieceForTeam:team squareSize:squareSize king:piece.king];
            pieceView.piece = piece;
            
            if (animatedMove && animatedMove.team == team && animatedMove.piece == i) {
                // Do nothing.  This move will be animated separately.
            } else if (vote
                       && [NSNumber number:vote.game isEqualToNumber:game.number]
                       && [NSNumber number:vote.turn isEqualToNumber:game.turn]
                       && [NSNumber number:vote.team isEqualToNumber:[NSNumber numberWithInt:team]]
                       && [NSNumber number:vote.piece isEqualToNumber:[NSNumber numberWithInt:i]]) {
                // Do nothing.  This move will be animated separately.
            } else {
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
    if (animatedMove) {
        CheckerboardPieceView * pieceView = [self viewForPiece:animatedMove.piece team:animatedMove.team];
        
        if (pieceView) {
            if (![self movePieceView:pieceView toLocations:animatedMove.locations animated:animated completion:^{}]) {
                // If the piece didn't move and the move matches the vote then we animate the
                // vote's shadow to indicate the move is confirmed.
                if ([animatedMove.locations isEqualToArray:vote.locations]) {
                    CheckerboardPieceView * voteMove = (voteMoves.count > 0 ? [voteMoves objectAtIndex:0] : nil);
                    
                    if (voteMove) {
                        [voteMoves removeObject:voteMove];
                        
                        [self movePieceView:voteMove
                                toLocations:animatedMove.locations
                                   animated:animated
                                 completion:^{
                                     [voteMove removeFromSuperview];
                                }];
                    }
                }
            }
        }
    }
    
    // Clean up previous vote moves.
    [self clearViews:voteMoves animated:animated];
    
    // Clean up any previous vote captures.
    [self clearViews:voteCaptures animated:animated];
    
    // Honor vote.
    if (vote
        && [NSNumber number:vote.game isEqualToNumber:game.number]
        && [NSNumber number:vote.turn isEqualToNumber:game.turn]) {
        
        GameTeam * voteTeam = [game.teams objectAtIndex:vote.team.intValue];
        GamePiece * votePiece = [voteTeam.pieces objectAtIndex:vote.piece.intValue];
        
        // Collect move shadow views.
        for (NSNumber * location in vote.locations) {
            CheckerboardPieceView * voteMove = [[CheckerboardPieceView alloc] initWithImage:[AppStyle pieceShadowForTeam:voteTeam.number squareSize:squareSize]];
            voteMove.piece = [((GameTeam *)[game.teams objectAtIndex:voteTeam.number]).pieces objectAtIndex:votePiece.number];
            
            [voteMoves addObject:voteMove];
            NSLog(@"location: %@", location);
        }
        
        // Collect capture and capture shadow views.
        GameValidMove * voteValidMove;
        for (GameValidMove * validMove in votePiece.validMoves) {
            if ([vote.locations isEqualToArray:validMove.locations]) {
                voteValidMove = validMove;
                break;
            }
        }
        NSMutableArray * captures = [NSMutableArray array];
        for (GameCapture * capture in voteValidMove.captures) {
            GameTeam * captureTeam = [game.teams objectAtIndex:capture.team];
            CheckerboardPieceView * voteCapture = [[CheckerboardPieceView alloc] initWithImage:[AppStyle pieceShadowForTeam:captureTeam.number squareSize:squareSize]];
            voteCapture.piece = [((GameTeam *)[game.teams objectAtIndex:capture.team]).pieces objectAtIndex:capture.piece];
            
            [captures addObject:[self viewForPiece:capture.piece team:capture.team]];
            [voteCaptures addObject:voteCapture];
        }
        
        // Execute.
        CheckerboardPieceView * votePieceView = [self viewForPiece:votePiece.number team:voteTeam.number];
        [self movePieceView:votePieceView
                toLocations:vote.locations
                    shadows:voteMoves
                   captures:captures
             captureShadows:voteCaptures
                       king:voteValidMove.king
                   animated:animated
                 completion:^{}];
    }
    
    [self layoutVotes];
    
    [self showHighlightsForPiecesWithValidMoves];
}

-(void)clearViews:(NSMutableArray *)views animated:(BOOL)animated {
    if (animated) {
        for (UIView * view in views) {
            [UIView animateWithDuration:0.15 animations:^{
                view.alpha = 0;
            } completion:^(BOOL finished) {
                [view removeFromSuperview];
            }];
        }
    } else {
        for (UIView * view in views) {
            [view removeFromSuperview];
        }
    }
    
    [views removeAllObjects];
}

-(BOOL)movePieceView:(CheckerboardPieceView *)pieceView
         toLocations:(NSArray *)locations
            animated:(BOOL)animated
          completion:(void (^)())completion {
    
    return [self movePieceView:pieceView toLocations:locations shadows:nil captures:nil captureShadows:nil king:NO animated:animated completion:completion];
}

-(BOOL)movePieceView:(CheckerboardPieceView *)pieceView
         toLocations:(NSArray *)locations
             shadows:(NSArray *)shadows
            captures:(NSArray *)captures
      captureShadows:(NSArray *)captureShadows
                king:(BOOL)king
            animated:(BOOL)animated
          completion:(void (^)())completion {
    
    // Determine if the piece will actually be moved.
    UIView * finalSquare = [self squareAtLocation:locations.lastObject];
    BOOL moved = !CGPointEqualToPoint(pieceView.center, finalSquare.center);
    
    // If we are already at the final location then we don't animate.
    animated = (animated && moved);
    
    // Bring view to front.
    [self bringSubviewToFront:pieceView];
    
    // Recursively move to each location, stopping for a moment at each
    // point, and capturing on the way over a piece.
    __block int i = 1;
    void(^animate)(void(^recursive)());
    animate = ^(void(^recursive)()) {
        if (i < locations.count) {
            NSNumber * location = [locations objectAtIndex:i];
            UIView * square = [self squareAtLocation:location];
            NSNumber * previousLocation = [locations objectAtIndex:i-1];
            UIView * previousSquare = [self squareAtLocation:previousLocation];
            float dx = (previousSquare.center.x - square.center.x);
            float dy = (previousSquare.center.y - square.center.y);
            float d = sqrtf(powf(dx, 2) + powf(dy, 2));
            
            // Move shadow to previous square location.
            UIView * shadow = (shadows.count > i - 1 ? [shadows objectAtIndex:i - 1] : nil);
            shadow.center = previousSquare.center;
            
            // Move capture shadow to capture location.
            UIView * capture = (captures.count > i - 1 ? [captures objectAtIndex:i - 1] : nil);
            UIView * captureShadow = (captureShadows.count > i - 1 ? [captureShadows objectAtIndex:i - 1] : nil);
            captureShadow.center = capture.center;
            
            if (animated) {
                [UIView animateWithDuration:(d / self.squareSize) * 0.1
                                      delay:(i > 1 ? 0.1 : 0)
                                    options:0
                                 animations:^{
                                     // Move piece.
                                     pieceView.center = square.center;
                                     
                                     // Leave shadow.
                                     [self insertSubview:shadow belowSubview:pieceView];
                                     
                                     // Capture and leave capture shadow.
                                     capture.alpha = 0;
                                     [self insertSubview:captureShadow belowSubview:pieceView];
                                 }
                                 completion:^(BOOL finished) {
                                     // King at end of last move.
                                     if (king && (i == locations.count - 1)) {
                                         pieceView.image = [AppStyle pieceForTeam:pieceView.piece.team squareSize:pieceView.frame.size.height king:YES];
                                     }
                                     
                                     i++;
                                     
                                     recursive(recursive);
                                 }];
            } else {
                // Move piece.
                pieceView.center = square.center;
                
                // Leave shadow.
                [self insertSubview:shadow belowSubview:pieceView];
                
                // Capture and leave capture shadow.
                capture.alpha = 0;
                [self insertSubview:captureShadow belowSubview:pieceView];
                
                // King at end of last move.
                if (king && (i == locations.count - 1)) {
                    pieceView.image = [AppStyle pieceForTeam:pieceView.piece.team squareSize:pieceView.frame.size.height king:YES];
                }
                
                i++;
                
                recursive(recursive);
            }
        } else {
            completion();
        }
    };
    animate(animate);
    
    return moved;
}

-(Vote *)vote {
    return vote;
}

-(void)setVote:(Vote *)theVote {
    vote = theVote;
    [self layoutGameAnimated:YES animatedMove:nil];
}

-(Votes *)votes
{
    return votes;
}

-(void)setVotes:(Votes *)theVotes
{
    votes = theVotes;
    
    [self layoutVotes];
}

-(void)layoutVotes
{
    // Transition out previous trending votes.
    for (UIView * votesView in votesViews) {
        [UIView animateWithDuration:0.5 animations:^{
            votesView.alpha = 0;
        } completion:^(BOOL finished) {
            [votesView removeFromSuperview];
        }];
    }
    [votesViews removeAllObjects];
    
    if (votes.moves.count > 0
        && [NSNumber number:votes.game isEqualToNumber:game.number]
        && [NSNumber number:votes.turn isEqualToNumber:game.turn]
        && [NSNumber number:votes.team isEqualToNumber:game.activeTeam]) {
    
        // Sort valid moves ascending based on count.
        NSArray * moves = [votes.moves sortedArrayUsingComparator:^NSComparisonResult(VotesMove * move1, VotesMove * move2) {
            if (move1.count.intValue > move2.count.intValue) {
                return NSOrderedDescending;
            } else if (move1.count.intValue < move2.count.intValue) {
                return NSOrderedAscending;
            }
            
            return NSOrderedSame;
        }];
    
        int totalTrendingCount = 0;
        for (VotesMove * votesMove in moves) {
            totalTrendingCount += votesMove.count.intValue;
        }
        
        float maxSize = 0.15f * self.squareSize;
        for (VotesMove * votesMove in moves) {
            UIImage * voteImage = [AppStyle drawTrendingPathForTeam:votesMove.team size:(((float)votesMove.count.intValue / (float)totalTrendingCount) * maxSize) locations:votesMove.locations squares:squares rect:self.bounds];
            UIImageView * votesView = [[UIImageView alloc] initWithImage:voteImage];
            votesView.alpha = 0;
            
            [votesViews addObject:votesView];
            [self addSubview:votesView];
            
            // Transition in trending votes.
            for (UIView * votesView in votesViews) {
                [UIView animateWithDuration:0.5 animations:^{
                    votesView.alpha = 1;
                }];
            }
        }
    }
}

- (void)ensureVotesAtFront
{
    for (UIView * votesView in votesViews) {
        [votesView.superview bringSubviewToFront:votesView];
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
