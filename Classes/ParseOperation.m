/*
     File: ParseOperation.m
 Abstract: The NSOperation class used to perform the XML parsing of earthquake data.
  Version: 2.3
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "ParseOperation.h"
#import "Currency.h"



// NSNotification name for sending earthquake data back to the app delegate
NSString *kAddCurrenciesNotif = @"AddCurrenciesNotif";

// NSNotification userInfo key for obtaining the earthquake data
NSString *kCurrencyResultsKey = @"CurrencyResultsKey";

// NSNotification name for reporting errors
NSString *kCurrenciesErrorNotif = @"CurrencyErrorNotif";

// NSNotification userInfo key for obtaining the error message
NSString *kCurrenciesMsgErrorKey = @"CurrenciesMsgErrorKey";


@interface ParseOperation () <NSXMLParserDelegate>
    @property (nonatomic, retain) Currency *currentObject;
    @property (nonatomic, retain) NSMutableArray *currentParseBatch;
    @property (nonatomic, retain) NSMutableString *currentParsedCharacterData;
@end

@implementation ParseOperation

@synthesize currenciesData, currentObject, currentParsedCharacterData, currentParseBatch;

- (id)initWithData:(NSData *)parseData
{
    if (self = [super init]) {    
        currenciesData = [parseData copy];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    }
    return self;
}

- (void)addCurrenciesToList:(NSArray *)currencies {
    assert([NSThread isMainThread]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCurrenciesNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:currencies
                                                                                           forKey:kCurrencyResultsKey]]; 
}
     
// the main function for this NSOperation, to start the parsing
- (void)main {
    self.currentParseBatch = [NSMutableArray array];
    self.currentParsedCharacterData = [NSMutableString string];
    
    // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is
    // not desirable because it gives less control over the network, particularly in responding to
    // connection errors.
    //
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.currenciesData];
    [parser setDelegate:self];
    [parser parse];
    
    
    if ([self.currentParseBatch count] > 0) {
        [self performSelectorOnMainThread:@selector(addCurrenciesToList:)
                               withObject:self.currentParseBatch
                            waitUntilDone:NO];
    }
    
    self.currentParseBatch = nil;
    self.currentObject = nil;
    self.currentParsedCharacterData = nil;
    
    [parser release];
}

- (void)dealloc {
    [currenciesData release];
    
    [currentObject release];
    [currentParsedCharacterData release];
    [currentParseBatch release];
    [dateFormatter release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark Parser constants
static NSUInteger kMaximumNumberOfCurrenciesToParse = 116;
static NSString * const kCurrencyElementName = @"currency";
static NSString * const kCurrenciesElementName = @"currencies";
static NSString * const kValueElementName = @"value";
static NSString * const kDateElementName = @"date";


#pragma mark -
#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
                                        namespaceURI:(NSString *)namespaceURI
                                       qualifiedName:(NSString *)qName
                                          attributes:(NSDictionary *)attributeDict {
	
    if (parsedCurrenciesNumber >= kMaximumNumberOfCurrenciesToParse) {
        didAbortParsing = YES;
        [parser abortParsing];
    }
	if ([elementName isEqualToString:kCurrenciesElementName]) {
		NSInteger numberOfCurrencies = [attributeDict valueForKey:@"count"];
		kMaximumNumberOfCurrenciesToParse = numberOfCurrencies;
	}
    if ([elementName isEqualToString:kCurrencyElementName]) {

        Currency *curr = [[Currency alloc] init];
		NSString *codeAttribute = [attributeDict valueForKey:@"code"];
		curr.code = codeAttribute;
		NSString *nameAttribute = [attributeDict valueForKey:@"name"];
		curr.description = nameAttribute;
		self.currentObject = curr;
        [curr release];
    } else if ([elementName isEqualToString:kValueElementName]) {
		NSString *dateAttribute = [attributeDict valueForKey:@"date"];
		self.currentObject.date = [dateFormatter dateFromString:dateAttribute];
		accumulatingParsedCharacterData = YES;
		[currentParsedCharacterData setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
                                      namespaceURI:(NSString *)namespaceURI
                                     qualifiedName:(NSString *)qName {     
    if ([elementName isEqualToString:kCurrencyElementName]) {
		[self.currentParseBatch addObject:self.currentObject];
		parsedCurrenciesNumber++;
        if ([self.currentParseBatch count] >= kMaximumNumberOfCurrenciesToParse) {
            [self performSelectorOnMainThread:@selector(addCurrenciesToList:)
                                   withObject:self.currentParseBatch
                                waitUntilDone:NO];
			self.currentParseBatch = [NSMutableArray array];
        }
		self.currentObject = nil;
    } else if ([elementName isEqualToString:kValueElementName]) {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
		CGFloat value;
		if ([scanner scanFloat:&value]) {
			self.currentObject.value = value;
			if (self.currentObject.value != 0.0) {
				self.currentObject.valueToDollars = 1.0 / value;
				
			}
		}
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
- (void)handleCurrenciesError:(NSError *)parseError {
    [[NSNotificationCenter defaultCenter] postNotificationName:kCurrenciesErrorNotif
                                                    object:self
                                                  userInfo:[NSDictionary dictionaryWithObject:parseError
                                                                                       forKey:kCurrenciesMsgErrorKey]];
}

// an error occurred while parsing the earthquake data,
// pass the error to the main thread for handling.
// (note: don't report an error if we aborted the parse due to a max limit of earthquakes)
//
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    if ([parseError code] != NSXMLParserDelegateAbortedParseError && !didAbortParsing)
    {
        [self performSelectorOnMainThread:@selector(handleCurrenciesError:)
                               withObject:parseError
                            waitUntilDone:NO];
    }
}

@end
