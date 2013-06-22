//
//  NTHXMLParser.m
//  EmilFrey
//
//  Created by Danijel Huis on 8/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
//	Description: Class intented for subclassing. Normal parser with automatic cache...
//	Usage:
/*
 XMLParserGarage *parser=[[XMLParserGarage alloc] initWithURL:fileDestination useCache:YES];
 [parser parse];			
 [itemArray release];
 itemArray=nil;
 if(!parser.errorOccurred) 
 {
	itemArray=[parser.itemArray retain];
 }
 [parser release];
*/

#import "NTHXMLParser.h"
#import "Cache.h"

@implementation NTHXMLParser
@synthesize filePath, errorOccurred;
-(id)initWithURL:(NSString *)_filePath useCache:(BOOL)_cache
{
	self.filePath=[NSString stringWithString:_filePath];
	cache=_cache;
	
	//===== Cache
	NTHXMLParser *parserTemp;
	if(cache) 
	{
		if(parserTemp=(NTHXMLParser *)[Cache getObjectForKey:self.filePath])
		{
			[self autorelease];
			self=[parserTemp retain];
			// Must be here because self is taken from cache in line above(so anythin we put before that line doesnt matter)
			cacheUsed=YES;
			
		}
	}
	//===== If not in cache...
	else self=[super init];
	return self;
}

- (void)parse
{	
	if(cacheUsed)	return;
	if(self.filePath==nil) return;
	NSURL *xmlURL=nil;
	if([self.filePath hasPrefix:@"http://"]) xmlURL = [NSURL URLWithString:self.filePath];
    else xmlURL = [NSURL fileURLWithPath:self.filePath];
	
	// NSXMLParser init
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
	
    //===== Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
    [parser setDelegate:self];
	
    //===== Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
	
	//===== Parsing
    [parser parse];
	//========== Cache
	if(cache && !self.errorOccurred) [Cache addObject:self forKey:self.filePath lifeInSeconds:60*5];	// Todo time
    [parser release];
}


-(void)dealloc
{
	[filePath release];
	[super dealloc];
}
@end
