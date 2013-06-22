//
//  NTHXMLParser.h
//  EmilFrey
//
//  Created by Danijel Huis on 8/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NTHXMLParser : NSObject 
{
	NSMutableString *currentStringValue;
	NSMutableString *currentElementName;
	NSString *filePath;
	BOOL errorOccurred;
	BOOL cache, cacheUsed;
}
@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, assign) BOOL errorOccurred;
-(id)initWithURL:(NSString *)_filePath useCache:(BOOL)_cache;
-(void)parse;
@end