

#import <UIKit/UIKit.h>
#import "MKHorizMenu.h"
#import "MBProgressHUD.h"
#import "CorePlot-CocoaTouch.h"

@class Rate;

@interface HistoryController : UIViewController <MKHorizMenuDataSource, MKHorizMenuDelegate, NSXMLParserDelegate, CPTPlotSpaceDelegate,
													CPTPlotDataSource,
													CPTScatterPlotDelegate>
{
	
	MKHorizMenu *_horizMenu;
    NSMutableArray *menuItems;
    
    NSString *selectedItem;
	
	NSMutableArray *ratesList;
	NSMutableArray *xAxisValues;
	NSMutableArray *displayData;
	
	NSString *srcCurrency;
	NSString *destCurrency;
	
	CPTLayerAnnotation   *symbolTextAnnotation;
	
@private
	// for downloading the xml data
	NSURLConnection *feedConnection;
	NSMutableData *historyData;
	
	NSOperationQueue *parseQueue;
	
	long long expectedLength;
	long long currentLength;
	
	CPTXYGraph *graph;
	CPTGraphHostingView *graphHostingView;
	
	MBProgressHUD *HUD;
	
	UILabel *noGraphLabel;
}

@property (nonatomic, retain) MKHorizMenu *horizMenu;
@property (nonatomic, retain) NSMutableArray *menuItems;
@property (nonatomic, retain) NSString *selectedItem;
@property (nonatomic, retain) NSMutableArray *ratesList;
@property (nonatomic, retain) NSMutableArray *xAxisValues;
@property (nonatomic, retain) CPTGraphHostingView *graphHostingView;
@property (nonatomic, retain) NSString *srcCurrency;
@property (nonatomic, retain) NSString *destCurrency;

-(void) fetchData;
-(void) reloadData;
-(float) getMinY;
-(float) getMaxY;
- (void)addRatesToList:(NSArray *)rates;
- (void)handleError:(NSError *)error;
-(void) adjustHorizontalView;
-(void) adjustVerticalView;

@end
