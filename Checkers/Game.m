//
//  Game.m
//  Checkers
//
//  Created by Wayne Carter on 8/20/13.
//  Copyright (c) 2013 Wayne Carter. All rights reserved.
//

#import "Game.h"

// Team
@implementation GameTeam

-(id)initWithData:(NSDictionary *)theData number:(int)number
{
    if (self = [self init]) {
        data = [theData mutableCopy];
        _number = number;
    }
    
    return self;
}

-(int)participantCount {
    return ((NSNumber *)[data objectForKey:@"participantCount"]).intValue;
}

-(NSArray *)pieces {
    if (pieces == nil) {
        NSMutableArray * mutablePieces = [NSMutableArray array];
        pieces = mutablePieces;
        
        NSArray * piecesData = [data objectForKey:@"pieces"];
        for (int i=0; i<piecesData.count; i++) {
            [mutablePieces addObject:[[GamePiece alloc] initWithData:[piecesData objectAtIndex:i] number:i team:self.number]];
        }
    }
    
    return pieces;
}

-(int)score
{
    int score = 0;
    
    for (GamePiece * piece in self.pieces) {
        if (!piece.captured) {
            score++;
        }
    }
    
    return score;
}

@end

// Piece
@implementation GamePiece

-(id)initWithData:(NSDictionary *)theData number:(int)number team:(int)team
{
    if (self = [self init]) {
        data = [theData mutableCopy];
        _number = number;
        _team = team;
    }
    
    return self;
}

-(NSNumber *)location {
    return [data objectForKey:@"location"];
}

-(void)setLocation:(NSNumber *)location {
    [data setObject:location forKey:@"location"];
}

-(NSMutableArray *)validMoves {
    if (validMoves == nil) {
        validMoves = [NSMutableArray array];
        
        for (NSDictionary * validMove in [data objectForKey:@"validMoves"]) {
            [validMoves addObject:[[GameValidMove alloc] initWithData:validMove piece:self]];
        }
    }
    
    return validMoves;
}

-(BOOL)captured {
    return ((NSNumber *)[data objectForKey:@"captured"]).boolValue;
}

-(void)setCaptured:(BOOL)captured {
    [data setObject:[NSNumber numberWithBool:captured] forKey:@"captured"];
}

-(BOOL)king {
    return ((NSNumber *)[data objectForKey:@"king"]).boolValue;
}

-(void)setKing:(BOOL)king{
    [data setObject:[NSNumber numberWithBool:king] forKey:@"king"];
}

@end

// Capture
@implementation GameCapture

-(id)initWithData:(NSDictionary *)theData
{
    if (self = [self init]) {
        data = [theData mutableCopy];
    }
    
    return self;
}

-(int)team {
    return ((NSNumber *)[data objectForKey:@"team"]).intValue;
}

-(int)piece {
    return ((NSNumber *)[data objectForKey:@"piece"]).intValue;
}

@end

// Move
@implementation GameMove

-(id)initWithData:(NSDictionary *)theData
{
    if (self = [self initWithTeam:((NSNumber *)[theData objectForKey:@"team"]).intValue piece:((NSNumber *)[theData objectForKey:@"piece"]).intValue locations:[theData objectForKey:@"locations"]]) {
        data = [theData mutableCopy];
    }
    
    return self;
}

-(id)initWithTeam:(int)theTeam piece:(int)thePiece locations:(NSArray *)theLocations {
    if (self = [self init]) {
        _team = theTeam;
        _piece = thePiece;
        _locations = theLocations;
    }
    
    return self;
}

@end

// Move
@implementation GameValidMove

-(id)initWithData:(NSDictionary *)theData piece:(GamePiece *)piece {
    NSMutableArray * locations = ((NSArray *)[theData objectForKey:@"locations"]).mutableCopy;
    if (locations.count == 0 || ![[locations objectAtIndex:0] isEqual:piece.location]) {
        [locations insertObject:piece.location atIndex:0];
    }
        
    if (self = [super initWithTeam:piece.team piece:piece.number locations:locations]) {
        data = [theData mutableCopy];
    }
    
    return self;
}

-(NSArray *)captures {
    if (captures == nil) {
        captures = [NSMutableArray array];
        
        for (NSDictionary * captureData in [data objectForKey:@"captures"]) {
            [captures addObject:[[GameCapture alloc] initWithData:captureData]];
        }
    }
    
    return captures;
}

-(BOOL)king {
    return ((NSNumber *)[data objectForKey:@"king"]).boolValue;
}

@end

// Game
static NSString * kCBCGameDateFormate = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
@implementation Game

-(id)initWithData:(NSData *)theData {
    NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:theData options:(NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves) error:nil];
    
    return [self initWithDictionary:dictionary];
}

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [self init]) {
        data = [dictionary mutableCopy];
    }
    
    return self;
}

-(NSNumber *)number {
    return [data objectForKey:@"number"];
}

-(NSDate *)startTime {
    if (startTime == nil) {
        NSString * startTimeString = [data objectForKey:@"startTime"];
        
        if (startTimeString) {
            NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
            [dateFormatter setDateFormat:kCBCGameDateFormate];
            
            startTime = [dateFormatter dateFromString:startTimeString];
        }
    }
    
    return startTime;
}

-(NSDate *)moveDeadline {
    if (moveDeadline == nil) {
        NSString * moveDeadlineString = [data objectForKey:@"moveDeadline"];
        
        if (moveDeadlineString) {
            NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
            [dateFormatter setDateFormat:kCBCGameDateFormate];
            
            moveDeadline = [dateFormatter dateFromString:moveDeadlineString];
        }
    }
    
    return moveDeadline;
}

-(NSNumber *)turn {
    return [data objectForKey:@"turn"];
}

-(NSNumber *)activeTeam {
    return [data objectForKey:@"activeTeam"];
}

-(NSNumber *)winningTeam {
    return [data objectForKey:@"winningTeam"];
}

-(NSArray *)teams {
    if (teams == nil) {
        NSMutableArray * mutableTeams = [NSMutableArray array];
        teams = mutableTeams;
        
        NSArray * teamsData = [data objectForKey:@"teams"];
        for (int i=0; i<teamsData.count; i++) {
            [mutableTeams addObject:[[GameTeam alloc] initWithData:[teamsData objectAtIndex:i] number:i]];
        }
    }
    
    return teams;
}

-(NSMutableArray *)moves {
    if (moves == nil) {
        moves = [NSMutableArray array];
        
        for (NSDictionary * moveData in [data objectForKey:@"moves"]) {
            [moves addObject:[[GameMove alloc] initWithData:moveData]];
        }
    }
    
    return moves;
}

-(BOOL)revotingAllowed {
    return ((NSNumber *)[data objectForKey:@"revotingAllowed"]).boolValue;
}

-(BOOL)highlightPiecesWithMoves {
    NSNumber * highlightPiecesWithMoves = [data objectForKey:@"highlightPiecesWithMoves"];
    
    return (highlightPiecesWithMoves ? highlightPiecesWithMoves.boolValue : YES);
}

-(NSString *)applicationName {
    return [data objectForKey:@"applicationName"];
}

-(NSString *)applicationUrl {
    NSString * url = [data objectForKey:@"applicationUrl"];
    if (!url) url = @"http://www.couchbase.com";
    
    return url;
}

@end
