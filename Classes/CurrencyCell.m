//
//  CurrencyCell.m
//  ExRate
//
//  Created by Maja on 11/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CurrencyCell.h"


@implementation CurrencyCell
@synthesize cImage, titleLabel, subtitleLabel, srcCurrencyLabel, destCurrencyLabel;

static NSUInteger const kTitleLabelTag = 2;
static NSUInteger const kSubtitleLabelTag = 3;
static NSUInteger const kSrcCurrencyLabelTag = 4;
static NSUInteger const kDestCurrencyLabelTag = 5;
static NSUInteger const kImageTag = 6;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self =  [super initWithStyle:style reuseIdentifier:reuseIdentifier]) != nil) {
	//	CGRect imageRect = CGRectMake(5.0f, 2.5f, 60.0f, 55.0f);
		cImage = [[[UIImageView alloc] init] autorelease];
		[cImage setTag:kImageTag];
		
	//	CGRect titleRect = CGRectMake(70.0f, 5.0, 140.0f, 27.5f);
		titleLabel = [[[UILabel alloc] init]autorelease];
		[titleLabel setFont: [UIFont fontWithName:@"STHeitiTC-Medium" size:16.0f]];
		[titleLabel setTag:kTitleLabelTag];
		
	//	CGRect subtitleRect = CGRectMake(70.0f, 32.5f, 140.0f, 22.5f);
		subtitleLabel = [[[UILabel alloc] init]autorelease];
		[subtitleLabel setFont: [UIFont fontWithName:@"STHeitiTC-Medium" size:13.0f]];
		[subtitleLabel setTextColor:[UIColor darkGrayColor]];
		[subtitleLabel setTag:kSubtitleLabelTag];
		
		
	//	CGRect srcCurrencyRect = CGRectMake(215.0, 5.0f, 100.0f, 22.5f);
		srcCurrencyLabel = [[[UILabel alloc] init] autorelease];
		[srcCurrencyLabel setFont: [UIFont fontWithName:@"STHeitiTC-Light" size:16.0f]];
		[srcCurrencyLabel setTextAlignment:UITextAlignmentRight];
		[srcCurrencyLabel setTag:kSrcCurrencyLabelTag];
		
	//	CGRect destCurrencyRect = CGRectMake(215.0, 32.5f, 100.0f, 22.5f);
		destCurrencyLabel = [[[UILabel alloc] init] autorelease];
		[destCurrencyLabel setFont: [UIFont fontWithName:@"STHeitiTC-Light" size:13.0f]];
		[destCurrencyLabel setTextAlignment:UITextAlignmentRight];
		[destCurrencyLabel setTag:kDestCurrencyLabelTag];
		
		[self.contentView addSubview:cImage];
		[self.contentView addSubview:titleLabel];
		[self.contentView addSubview:subtitleLabel];
		[self.contentView addSubview:srcCurrencyLabel];
		[self.contentView addSubview:destCurrencyLabel];
		
	}
	return self;
}

-(void) layoutSubviews {
	[super layoutSubviews];
	CGRect contentRect=self.contentView.bounds;
	CGFloat boundsX = contentRect.origin.x + 70.0f;
	CGRect frame;
	
	frame = CGRectMake(5.0f, 2.5f, 60.0f, 55.0f);
	cImage.frame = frame;
	
	frame = CGRectMake(boundsX, 5.0, 80.0f, 27.5f);
	titleLabel.frame = frame;
	
	frame = CGRectMake(70.0f, 32.5f, 140.0f, 22.5f);
	subtitleLabel.frame = frame;
	
	frame = CGRectMake(145.0f, 5.0f, 175.0f, 22.5f);
	srcCurrencyLabel.frame = frame;
	
	frame = CGRectMake(215.0, 32.5f, 100.0f, 22.5f);
	destCurrencyLabel.frame = frame;

}

-(void) dealloc {
	[super dealloc];
}

@end
