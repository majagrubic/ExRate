//
//  HistoryParseOperation.h
//  ExRate
//
//  Created by Maja on 10/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kAddHistoryNotif;
extern NSString *kHistoryResultsKey;

extern NSString *kHistoryErrorNotif;
extern NSString *kHistoryMsgErrorKey;

@class Rate;

@interface HistoryParseOperation : NSOperation{
	NSData *historyData;
	
@private
    NSDateFormatter *dateFormatter;
    
    // these variables are used during parsing
	Rate *currentObject;
    NSMutableString *currentParsedCharacterData;
	NSMutableArray *currentParseBatch;
	
	BOOL accumulatingParsedCharacterData;
    BOOL didAbortParsing;
    NSUInteger parsedRatesNumber;
}

@property (copy, readonly) NSData *historyData;

@end
