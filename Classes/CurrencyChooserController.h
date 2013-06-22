//
//  CurrencyChooserController.h
//  ExRate
//
//  Created by Maja on 10/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#define rowHeight 60

@class Currency;
@class CurrencyController;

@interface CurrencyChooserController : UIViewController<UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource> {

	UITableView *tableView;
	NSArray *currencyList;
	NSMutableArray *searchResults;
	UISearchBar *searchBar;
	NSIndexPath *checkedIndexPath;
	CurrencyController *currController;
	BOOL searching;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSArray *currencyList;
@property (nonatomic, retain) NSMutableArray *searchResults;
@property (nonatomic, retain) NSIndexPath *checkedIndexPath;
@property (nonatomic, retain) CurrencyController *currController;

-(void) cancel;
-(void) searchTableView;

@end
