//
//  Currency.m
//  ExRate
//
//  Created by Maja on 10/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Currency.h"

@implementation Currency

@synthesize value;
@synthesize valueToDollars;
@synthesize code;
@synthesize date;
@synthesize description;
@synthesize imagePath;

static NSString * const keyCode = @"code";
static NSString * const keyDescription = @"description";
static NSString * const keyValue = @"value";
static NSString * const keyValueDollars = @"valueToDollars";

- (void)dealloc {
	[code release];
    [date release];
	[description release];
	[imagePath release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if ([coder allowsKeyedCoding]) {
		[coder encodeObject:code forKey: keyCode];
	}
	[coder encodeObject:description forKey: keyDescription];
	[coder encodeFloat:value forKey: keyValue];
	[coder encodeFloat:valueToDollars forKey:keyValueDollars];
	 
}

- (id)initWithCoder:(NSCoder *) coder {
	self = [[Currency alloc] init];
    if (self != nil)
    {
        code = [[coder decodeObjectForKey:keyCode] retain];
		description = [[coder decodeObjectForKey:keyDescription] retain];
		value = [coder decodeFloatForKey:keyValue];
		valueToDollars = [coder decodeFloatForKey:keyValueDollars];
    }   
    return self;
	

}





@end
