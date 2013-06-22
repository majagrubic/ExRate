//
//  ExRateAppDelegate.h
//  ExRate
//
//  Created by Maja on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"


@class CurrencyController;
@class Currency;
@class Reachability;

@interface ExRateAppDelegate : NSObject <UIApplicationDelegate, NSXMLParserDelegate, MBProgressHUDDelegate, UIAlertViewDelegate> {
	UIWindow *_window;
	
	
@private
	// for downloading the xml data
	NSURLConnection *feedConnection;
	NSMutableData *currenciesData;

	NSOperationQueue *parseQueue;
	CurrencyController *cController;
	
	MBProgressHUD *HUD;
	
	BOOL didUpdate;
	
	long long expectedLength;
	long long currentLength;
	Reachability* internetReach;
	
}

@property(nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) CurrencyController *cController;


-(BOOL) shouldFetchData;
-(void) saveDate;
-(void) fetchData:(BOOL)showHUD;
-(NSString*) lastUpdated;
-(NSArray*) loadDataSavedLocally;
-(void) updateInterfaceWithReachability:(Reachability *)curReach;

@end

