//
//  CurrencyCell.h
//  ExRate
//
//  Created by Maja on 11/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CurrencyCell : UITableViewCell {

	UILabel *titleLabel;
    UILabel *subtitleLabel;
    UILabel *srcCurrencyLabel;
	UILabel *destCurrencyLabel;
    UIImageView *cImage;
}

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *subtitleLabel;
@property (nonatomic, retain) UILabel *srcCurrencyLabel;
@property (nonatomic, retain) UILabel *destCurrencyLabel;
@property (nonatomic, retain) UIImageView *cImage;



@end
