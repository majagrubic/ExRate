//
//  Rate.h
//  ExRate
//
//  Created by Maja on 10/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Rate : NSObject {

	NSDate *date;
	CGFloat value;
}

@property (nonatomic, assign) CGFloat value;
@property (nonatomic, retain) NSDate *date;

@end
