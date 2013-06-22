//
//  CurrencyController.h
//  ExRate
//
//  Created by Maja on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"
#import "TKEmptyView.h"

@class Currency;
@class Reachability;
@interface CurrencyController : UIViewController<UITextFieldDelegate, UITableViewDelegate,
										UITableViewDataSource, EGORefreshTableHeaderDelegate> {
	
	UITextField *textFieldNormal;
	UIButton *headerView;
	UITableView *tableView;
	NSMutableArray *currencyList;
	Currency *baseCurrency;
    NSNumberFormatter *numberFormatter;
	UIToolbar *keyboardToolbar;

	EGORefreshTableHeaderView *_refreshHeaderView;
	BOOL _reloading;
	TKEmptyView *emptyView;
	UIButton *button;
											
	BOOL showingEmptyView;
    BOOL inverse;
	
}


@property (nonatomic, retain) UITextField *textFieldNormal;
@property (nonatomic, retain, readonly) UIButton *headerView;
@property  (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSMutableArray *currencyList;
@property (nonatomic, retain) Currency *baseCurrency;
@property (nonatomic, retain) NSNumberFormatter *numberFormatter;
@property (nonatomic, assign) BOOL reloading;
@property  (nonatomic, assign) BOOL showingEmptyView;

-(UITextField*) initTextField;
-(void)doneButton:(id)sender;
-(void)showCurrencyChooser:(id)sender;
-(void)initHeaderView;
-(void)insertCurrencies:(NSArray *)currencies;   
-(void)inverse;
-(void) showInfo;
- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;
- (void) updateTable:(id)sender;
- (void) showEmptyView;
-(void) showView;


@end
