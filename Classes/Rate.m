//
//  Rate.m
//  ExRate
//
//  Created by Maja on 10/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Rate.h"



@implementation Rate

@synthesize date;
@synthesize value;

- (void)dealloc {
	[date release];
    [super dealloc];
}


@end
