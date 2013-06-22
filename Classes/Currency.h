//
//  Currency.h
//  ExRate
//
//  Created by Maja on 10/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Currency : NSObject<NSCoding>{
	CGFloat value;
	CGFloat valueToDollars;
    NSString *code;
	NSDate *date;
	NSString *description;
	NSString *imagePath;
}


@property (nonatomic, assign) CGFloat value;
@property (nonatomic, retain) NSString *code;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *imagePath;
@property (nonatomic, assign)  CGFloat valueToDollars;
@end
