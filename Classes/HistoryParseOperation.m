//
//  HistoryParseOperation.m
//  ExRate
//
//  Created by Maja on 10/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HistoryParseOperation.h"
#import "Rate.h"


NSString *kAddHistoryNotif = @"AddHistoryNotif";
NSString *kHistoryResultsKey = @"HistoryResultsKey";
NSString *kHistoryErrorNotif = @"HistoryErrorNotif";
NSString *kHistoryMsgErrorKey = @"HistoryMsgErrorKey";


@interface HistoryParseOperation () <NSXMLParserDelegate>
@property (nonatomic, retain) Rate *currentObject;
@property (nonatomic, retain) NSMutableString *currentParsedCharacterData;
@property (nonatomic, retain) NSMutableArray *currentParseBatch;
@end

@implementation HistoryParseOperation

@synthesize historyData, currentObject, currentParsedCharacterData, currentParseBatch;

- (id)initWithData:(NSData *)parseData
{
    if (self = [super init]) {    
        historyData = [parseData copy];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return self;
}

- (void)addRatesToList:(NSArray *)rates {
    assert([NSThread isMainThread]);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddHistoryNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:rates
                                                                                           forKey:kHistoryResultsKey]]; 
}

// the main function for this NSOperation, to start the parsing
- (void)main {
    self.currentParseBatch = [[NSMutableArray alloc] init];
    self.currentParsedCharacterData = [NSMutableString string];
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.historyData];
    [parser setDelegate:self];
    [parser parse];
    
    
    if ([self.currentParseBatch count] > 0) {
		NSLog(@"History Parse Operation ");
        [self performSelectorOnMainThread:@selector(addRatesToList:)
                               withObject:self.currentParseBatch
                            waitUntilDone:NO];
    }
    
    self.currentParseBatch = nil;
    self.currentObject = nil;
    self.currentParsedCharacterData = nil;
    
    [parser release];
}

- (void)dealloc {
    [historyData release];
    
    [currentObject release];
    [currentParsedCharacterData release];
    [currentParseBatch release];
    [dateFormatter release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark Parser constants
static NSString * const kRateElementName = @"rate";
static NSString * const kDateElementName = @"date";


#pragma mark -
#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
	attributes:(NSDictionary *)attributeDict {
	
    if ([elementName isEqualToString:kRateElementName]) {
        Rate *rate = [[Rate alloc] init];
		NSString *dateAttribute = [attributeDict valueForKey:@"date"];
		rate.date = [dateFormatter dateFromString:dateAttribute];
		NSLog(@"Date %@", [dateFormatter stringFromDate:rate.date]);
		self.currentObject = rate;
		rate.value = 1;
		[rate release];
		accumulatingParsedCharacterData = YES;
		[currentParsedCharacterData setString:@""];
    } 
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {     

	if ([elementName isEqualToString:kRateElementName]) {
		NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
		CGFloat value;
		if ([scanner scanFloat:&value]) {
			self.currentObject.value = value;
		}
		[self.currentParseBatch addObject:self.currentObject];
		parsedRatesNumber++;
		self.currentObject = nil;
    } else if ([elementName isEqualToString:@"rates"]) {
		[self performSelectorOnMainThread:@selector(addRatesToList:)
							   withObject:self.currentParseBatch
							waitUntilDone:NO];
		self.currentParseBatch = [NSMutableArray array];
	} 
	
    // Stop accumulating parsed character data. We won't start again until specific elements begin.
    accumulatingParsedCharacterData = NO;
}

// This method is called by the parser when it find parsed character data ("PCDATA") in an element.
// The parser is not guaranteed to deliver all of the parsed character data for an element in a single
// invocation, so it is necessary to accumulate character data until the end of the element is reached.
//
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (accumulatingParsedCharacterData) {
		
        [self.currentParsedCharacterData appendString:string];
    }
}

// an error occurred while parsing the earthquake data,
// post the error as an NSNotification to our app delegate.
// 
- (void)handleHistoryError:(NSError *)parseError {
    [[NSNotificationCenter defaultCenter] postNotificationName:kHistoryErrorNotif
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:parseError
																						   forKey:kHistoryMsgErrorKey]];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    if ([parseError code] != NSXMLParserDelegateAbortedParseError && !didAbortParsing)
    {
        [self performSelectorOnMainThread:@selector(handleHistoryError:)
                               withObject:parseError
                            waitUntilDone:NO];
    }
}

@end
