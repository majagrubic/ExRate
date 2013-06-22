    //
//  HistoryController.m
//  ExRate
//
//  Created by Maja on 10/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HistoryController.h"
#import "HistoryParseOperation.h"
#import "Rate.h"
#import "CPTGraphHostingView.h"
#import "math.h"
#import "MKInfoPanel.h"


@interface HistoryController ()

@property (nonatomic, retain) NSURLConnection *feedConnection;
@property (nonatomic, retain) NSMutableData *historyData;    // the data returned from the NSURLConnection
@property (nonatomic, retain) NSOperationQueue *parseQueue;     // the queue that manages our NSOperation for parsing earthquake data


@end


@implementation HistoryController
@synthesize horizMenu = _horizMenu;
@synthesize menuItems;
@synthesize selectedItem;
@synthesize feedConnection;
@synthesize historyData;
@synthesize parseQueue;
@synthesize ratesList;
@synthesize xAxisValues;
@synthesize graphHostingView;
@synthesize srcCurrency, destCurrency;

static NSString * const k5d = @"5d";
static NSString * const k1m = @"1m";
static NSString * const k3m = @"3m";
static NSString * const k6m = @"6m";
static NSString * const k1y = @"1y";
static NSString * const k2y = @"2y";
static NSString * const k5y = @"5y";
static NSString * const requestStr = @"http://gw.udovicic.com/exrate/history.php?t=%@&from=%@&to=%@";
static float const graphRed = 0.0;
static float  const graphGreen = 136.0 / 255;
static float const graphBlue = 255.0 / 255;



// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"Init with nib");
    }
    return self;
}*/


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	self.title = [NSString stringWithFormat:@"%@ / %@", srcCurrency, destCurrency];
	self.menuItems = [NSArray arrayWithObjects:k5d, k1m, k3m, k6m, k1y, k2y, k5y, nil];    
	self.xAxisValues = [[NSMutableArray alloc] init];
	ratesList = [[NSMutableArray alloc] init];
	displayData = [[NSMutableArray alloc] init];

	[self.view setAutoresizesSubviews:YES];
    [self.view setBackgroundColor:[UIColor blackColor]];
	
	//horiz Menu
	self.horizMenu = [[MKHorizMenu alloc] initWithFrame:CGRectMake(0, 0, 320, 41)];
	self.horizMenu.dataSource = self;
	self.horizMenu.itemSelectedDelegate = self;
	[self.horizMenu awakeFromNib];
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSString *srcHistoryCurrency = [prefs stringForKey:@"srcHistoryCurrency"];
	NSString *destHistoryCurrency = [prefs stringForKey:@"destHistoryCurrency"];
	NSInteger sItem = [prefs integerForKey:@"selectedHistoryItem"];
	if (srcHistoryCurrency != nil && [srcHistoryCurrency isEqualToString:srcCurrency] 
		&& destHistoryCurrency && [destHistoryCurrency isEqualToString:destCurrency]) 
	{
		[self.horizMenu setSelectedIndex:sItem animated:YES];
		selectedItem = [self.menuItems objectAtIndex:sItem];
	} else {
		[self.horizMenu setSelectedIndex:0 animated:NO];
	}
	[self.horizMenu reloadData];
	[self.view addSubview:self.horizMenu];

	graphHostingView = [[CPTGraphHostingView alloc] initWithFrame:CGRectMake(0, 43, 320, 380)];
	graphHostingView.collapsesLayers = NO; // Setting to YES reduces GPU memory usage, but can slow drawing/scrolling
	[graphHostingView setAutoresizesSubviews:YES];
			
	[self.view addSubview:graphHostingView];
	
	noGraphLabel = [[UILabel alloc] initWithFrame:CGRectMake(65, 250, 200, 30)];
	noGraphLabel.textColor = [UIColor whiteColor];
	noGraphLabel.backgroundColor = [UIColor clearColor];
	noGraphLabel.text = @"No history data available";
	[noGraphLabel setFont: [UIFont boldSystemFontOfSize:16]];
	
	[super viewDidLoad];
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && (ratesList == nil || [ratesList count] == 0)) {
		return NO;
	}
	return YES;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration  {
	[[self navigationController] setNavigationBarHidden:UIInterfaceOrientationIsLandscape(toInterfaceOrientation) animated:YES];
  //  [[UIApplication sharedApplication] setStatusBarHidden:UIInterfaceOrientationIsLandscape(toInterfaceOrientation) animated:YES];
	if (self.horizMenu) {
		[self.horizMenu removeFromSuperview];
	}
	if (symbolTextAnnotation) {
		symbolTextAnnotation = nil;
	}
	if (graphHostingView) {
		[self.graphHostingView removeFromSuperview];
		[graphHostingView release];
		graphHostingView = nil;
		[graph release];
		graph = nil;
	}
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	if (UIInterfaceOrientationIsPortrait(fromInterfaceOrientation)) {
		[self adjustHorizontalView];
	} else  {
		[self adjustVerticalView];
	}
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

-(void) viewWillAppear:(BOOL)animated {

}

- (void) adjustHorizontalView {
	
	graphHostingView = [[CPTGraphHostingView alloc] initWithFrame:CGRectMake(0, 0, 480, 300)];
	graphHostingView.collapsesLayers = NO; // Setting to YES reduces GPU memory usage, but can slow drawing/scrolling
	//self.navigationItem.navigationBarHidden = YES;
	[self.view addSubview:graphHostingView];
	[self reloadData];
}

-(void) adjustVerticalView {
	if (graphHostingView) {
		[self.graphHostingView removeFromSuperview];
		[graphHostingView release];
		graphHostingView = nil;
		[graph release];
		graph = nil;
	}
	graphHostingView = [[CPTGraphHostingView alloc] initWithFrame:CGRectMake(0, 43, 320, 380)];
	graphHostingView.collapsesLayers = NO; // Setting to YES reduces GPU memory usage, but can slow drawing/scrolling
		
	[self.view addSubview:self.horizMenu];
	[self.view addSubview:graphHostingView];
	[self reloadData];
}

-(void)reloadData
{
	CPTScatterPlot *boundLinePlot;
    if(!graph)
    {
		graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
		CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
		[graph applyTheme:theme];
	
		graph.paddingLeft = 10.0;
		graph.paddingTop = 10.0;
		graph.paddingRight = 10.0;
		graph.paddingBottom = 10.0;
		graph.plotAreaFrame.paddingLeft = 35.0;
		graph.plotAreaFrame.paddingBottom = 40.0;

		boundLinePlot = [[[CPTScatterPlot alloc] init] autorelease];
		CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];;
		lineStyle.lineWidth = 2.0f;
		lineStyle.lineColor = [CPTColor colorWithComponentRed:graphRed green:graphGreen blue:graphBlue alpha:1.0];
		boundLinePlot.dataLineStyle = lineStyle;
		boundLinePlot.identifier = @"History Plot";
		boundLinePlot.dataSource = self;
		
		// Put an area gradient under the plot above
		CPTColor *areaColor = [CPTColor colorWithComponentRed:graphRed green:graphGreen blue:graphBlue alpha:0.8];
		CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor colorWithComponentRed:graphRed green:graphGreen blue:graphBlue alpha:0.2]];
		areaGradient.angle = -90.0;
		CPTFill* areaGradientFill = [CPTFill fillWithGradient:areaGradient];
		boundLinePlot.areaFill = areaGradientFill;
						
		boundLinePlot.delegate = self;
		
		[graph addPlot:boundLinePlot];
		graphHostingView.hostedGraph = graph;
	} else {
		boundLinePlot = (CPTScatterPlot*) [graph plotWithIdentifier:@"History Plot"];
	}
	
	float minY = [self getMinY];
	float maxY = [self getMaxY];
	
	Rate *r = [ratesList objectAtIndex:0];
	NSDate *refDate = r.date;
    NSTimeInterval oneDay = 24 * 60 * 60;

	// Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;		
		
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
	if ([selectedItem isEqualToString:k5d] || [selectedItem isEqualToString:k1m]) {
		[dateFormatter setDateFormat:@"dd MMM"];
	} else if ([selectedItem isEqualToString:k1y] || [selectedItem isEqualToString:k2y] || [selectedItem isEqualToString:k5y]) {
		[dateFormatter setDateFormat:@"MMM yyyy"];
	} else if ([selectedItem isEqualToString:k3m] || [selectedItem isEqualToString:k6m]) {
		[dateFormatter setDateFormat:@"MMM"];
	}
    CPTTimeFormatter *timeFormatter = [[[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter] autorelease];
	timeFormatter.referenceDate = refDate;
   
	// Axes
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
	int intervalLength;

	if ([selectedItem isEqualToString:k5d]) {
		intervalLength = 1;
	} else if ([selectedItem isEqualToString:k1m]) {
		intervalLength = 5;
	} else if ([selectedItem isEqualToString:k3m]) {
		intervalLength = 31;
	} else if ([selectedItem isEqualToString:k6m]) {
		intervalLength = 31;
	} else if ([selectedItem isEqualToString:k1y]) {
		intervalLength = 4*30;
	} else if ([selectedItem isEqualToString:k2y]) {
		intervalLength = 8*30;
	} else if ([selectedItem isEqualToString:k5y]) {
		intervalLength = 12*30;
	}
	
	[plotSpace scaleToFitPlots:[NSArray arrayWithObjects:boundLinePlot, nil]];
	CPTPlotRange *xRange = plotSpace.xRange;
    CPTPlotRange *yRange = plotSpace.yRange;
	[xRange expandRangeByFactor:CPTDecimalFromFloat(1.2)]; 
	[yRange expandRangeByFactor:CPTDecimalFromFloat(1.2)];
	plotSpace.yRange = yRange;
	
	if ((maxY - minY) < 0.01) {
		float minYRange = minY - 0.01;
		// Restrict y range to a global range
		CPTPlotRange *globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(minY)
																length:CPTDecimalFromFloat(minY)];
		plotSpace.globalYRange = globalYRange;
	}
	
    boundLinePlot.areaBaseValue = CPTDecimalFromFloat(minY);

	CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
	
	x.majorIntervalLength = CPTDecimalFromFloat(intervalLength*oneDay);
	x.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
	x.orthogonalCoordinateDecimal =CPTDecimalFromFloat(minY);
	x.preferredNumberOfMajorTicks = 6;
	x.minorTicksPerInterval = 0;
	x.labelFormatter = timeFormatter;
	x.labelRotation = M_PI/5;
	x.majorGridLineStyle = majorGridLineStyle;

 	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:3];
	//[numberFormatter setRoundingIncrement:[NSNumber numberWithDouble:0.001]];
	[numberFormatter setPositiveFormat:@"###0.000"];	
	if (r.value > 1000) {
		[numberFormatter setPositiveFormat:@"###0.0"];	
	} else if (r.value > 100) {
		[numberFormatter setPositiveFormat:@"###0.00"];
	}
	CPTXYAxis *y = axisSet.yAxis;
	y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
	y.majorIntervalLength = CPTDecimalFromDouble(1);
    y.minorTicksPerInterval = 1;
	y.preferredNumberOfMajorTicks = 5;
	if (r.value / (maxY - minY) > 100) {
		y.preferredNumberOfMajorTicks = 3;
	}
	y.labelOffset = 5.0;
	y.labelFormatter = numberFormatter;
	y.labelExclusionRanges = [NSArray arrayWithObjects: [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) 
																		length:CPTDecimalFromFloat(minY)], nil];
	// Add plot symbols
    CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
    symbolLineStyle.lineColor = [CPTColor blackColor];
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:graphRed green:graphGreen blue:graphBlue alpha:0.9]];
    plotSymbol.lineStyle = symbolLineStyle;
    plotSymbol.size = CGSizeMake(0.0, 0.0);
    boundLinePlot.plotSymbol = plotSymbol;
	boundLinePlot.plotSymbolMarginForHitDetection = 5.0f;
	
	[graph reloadData];
	if (HUD) [HUD hide:NO];
	[self.view setNeedsLayout];	
}

#pragma mark -
#pragma mark CPTScatterPlot delegate method
-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)index
{
    if ( symbolTextAnnotation ) {
        [graph.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
        symbolTextAnnotation = nil;
    }
	
    // Setup a style for the annotation
    CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
    hitAnnotationTextStyle.color = [CPTColor whiteColor];
    hitAnnotationTextStyle.fontSize = 16.0f;
    hitAnnotationTextStyle.fontName = @"Helvetica-Bold";
	
    // Determine point of symbol in plot coordinates
    NSNumber *x = [xAxisValues objectAtIndex:index];
	Rate *r = [ratesList objectAtIndex:index];
    NSNumber *y = [NSNumber numberWithFloat:r.value];
    NSArray *anchorPoint = [NSArray arrayWithObjects:x, y, nil];
	
    // Add annotation
    // First make a string for the y value
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setMaximumFractionDigits:3];
	[formatter setPositiveFormat:@"##0.000"];
    NSString *yString = [formatter stringFromNumber:y];
	
    // Now add the annotation to the plot area
    CPTTextLayer *textLayer = [[[CPTTextLayer alloc] initWithText:yString style:hitAnnotationTextStyle] autorelease];
    symbolTextAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint];
    symbolTextAnnotation.contentLayer = textLayer;
    symbolTextAnnotation.displacement = CGPointMake(0.0f, 20.0f);
    [graph.plotAreaFrame.plotArea addAnnotation:symbolTextAnnotation];    
}


-(void) fetchData {
	[noGraphLabel removeFromSuperview];
	[xAxisValues removeAllObjects];
	[ratesList removeAllObjects];
	
	NSString *feedURLString = [NSString stringWithFormat:requestStr, selectedItem, srcCurrency, destCurrency];
	NSURLRequest *historyURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
	self.feedConnection = [[[NSURLConnection alloc] initWithRequest:historyURLRequest delegate:self] autorelease];

	NSAssert(self.feedConnection != nil, @"Failure to create URL connection.");
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	HUD = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
	
	if (parseQueue) {
		[parseQueue release];
		parseQueue = nil;
	}
	parseQueue = [NSOperationQueue new];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(addRates:)
												 name:kAddHistoryNotif
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(historyError:)
												 name:kHistoryErrorNotif
											   object:nil];
}



- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    
	[self removeObserver:self forKeyPath:@"ratesList"];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kAddHistoryNotif object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kHistoryErrorNotif object:nil];
	[super viewDidUnload];
}


- (void)dealloc {
	[_horizMenu release];
	[menuItems release];
	[selectedItem release];
	[xAxisValues release];
	[graph	 release];
	[ratesList release];
	[graphHostingView release];
	[srcCurrency release];
	[destCurrency release];
    [super dealloc];
}

#pragma mark -
#pragma mark HorizMenu Data Source
- (UIImage*) selectedItemImageForMenu:(MKHorizMenu*) tabMenu
{
    return [[UIImage imageNamed:@"ButtonSelected"] stretchableImageWithLeftCapWidth:16 topCapHeight:0];
}

- (UIColor*) backgroundColorForMenu:(MKHorizMenu *)tabView
{
	//return [UIColor lightGrayColor];
    return [UIColor colorWithPatternImage:[UIImage imageNamed:@"MenuBar"]];
}

- (int) numberOfItemsForMenu:(MKHorizMenu *)tabView
{
    return [self.menuItems count];
}

- (NSString*) horizMenu:(MKHorizMenu *)horizMenu titleForItemAtIndex:(NSUInteger)index
{
    return [self.menuItems objectAtIndex:index];
}

#pragma mark -
#pragma mark HorizMenu Delegate
-(void) horizMenu:(MKHorizMenu *)horizMenu itemSelectedAtIndex:(NSUInteger)index
{        
	if ([selectedItem isEqualToString:[self.menuItems objectAtIndex:index]]) {
		return;
	}
    selectedItem = [self.menuItems objectAtIndex:index];
	if (graph) {
		if ( symbolTextAnnotation ) {
			[graph.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
			symbolTextAnnotation = nil;
		}
		[graph release];
		graph = nil;
	}
	 graphHostingView.hostedGraph = nil;
	//if (graphHostingView) {
//        [graphHostingView removeFromSuperview];
//        
//        graphHostingView.hostedGraph = nil;
//        [graphHostingView release];
//        graphHostingView = nil;
//    }
	
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"selectedHistoryItem"];
	[[NSUserDefaults standardUserDefaults] setObject:srcCurrency forKey:@"srcHistoryCurrency"];
	[[NSUserDefaults standardUserDefaults] setObject:destCurrency forKey:@"destHistoryCurrency"];
	[xAxisValues removeAllObjects];
	[ratesList removeAllObjects];
	[self fetchData];
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

// The following are delegate methods for NSURLConnection. Similar to callback functions, this is
// how the connection object, which is working in the background, can asynchronously communicate back
// to its delegate on the thread from which it was started - in this case, the main thread.
//
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // check for HTTP status code for proxy authentication failures
    // anything in the 200 to 299 range is considered successful,
	HUD.mode = MBProgressHUDModeDeterminate;
	expectedLength = [response expectedContentLength];
	currentLength = 0;
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (([httpResponse statusCode]/100) == 2) { //&& [[response MIMEType] isEqual:@"application/atom+xml"]) {
        self.historyData = [NSMutableData data];
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:
                                  NSLocalizedString(@"HTTP Error",
                                                    @"Error message displayed when receving a connection error.")
                                                             forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"HTTP" code:[httpResponse statusCode] userInfo:userInfo];
       [self handleError:error];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	currentLength += [data length];
	[historyData appendData:data];
	HUD.progress = currentLength / (float)expectedLength;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;   

    if ([error code] == kCFURLErrorNotConnectedToInternet) {
        // if we can identify the error, we can present a more precise message to the user.
        NSDictionary *userInfo =
        [NSDictionary dictionaryWithObject:
         NSLocalizedString(@"No Connection Error",
                           @"Not connected to the Internet.")
                                    forKey:NSLocalizedDescriptionKey];
        NSError *noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                         code:kCFURLErrorNotConnectedToInternet
                                                     userInfo:userInfo];
		
		[self handleError:noConnectionError];
    } else {
        [self handleError:error];
    }
    self.feedConnection = nil;
	[HUD hide:NO];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	self.feedConnection = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;   
    
	HistoryParseOperation *parseOperation = [[HistoryParseOperation alloc] initWithData:self.historyData];
    [self.parseQueue addOperation:parseOperation];
    [parseOperation release];   // once added to the NSOperationQueue it's retained, we don't need it anymore
    
	self.historyData = nil;
}

- (void)addRates:(NSNotification *)notif {
    assert([NSThread isMainThread]);
	[self.ratesList removeAllObjects];
	[self.xAxisValues removeAllObjects];
	[displayData removeAllObjects];
    [self addRatesToList:[[notif userInfo] valueForKey:kHistoryResultsKey]];
}

- (void)historyError:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    [self handleError:[[notif userInfo] valueForKey:kHistoryMsgErrorKey]];
}

- (void)addRatesToList:(NSArray *)rates {
	if (rates == nil || [rates count] == 0) {
		[self.view addSubview:noGraphLabel];
		if (HUD) [HUD hide:NO];
		[self.view setNeedsLayout];
		return;
	}
	[self willChangeValueForKey:@"ratesList"];
    [self.ratesList addObjectsFromArray:rates];
    [self didChangeValueForKey:@"ratesList"];
	Rate *r = [ratesList objectAtIndex:0];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd"];
	NSDate *refDate = r.date;
	for (int i=0; i<[rates count]; i++) {
		r = [rates objectAtIndex:i];
		CGFloat f = [r.date timeIntervalSinceDate:refDate];
		[xAxisValues addObject:[NSDecimalNumber numberWithFloat:f]];
		[displayData addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[xAxisValues objectAtIndex:i], @"x", [ratesList objectAtIndex:i], @"y", nil]];
	}
	[formatter release];
	[self reloadData];
}

- (void)handleError:(NSError *)error {
	NSLog(@"Error %@", [error localizedDescription]);
	if ([error code] == kCFURLErrorNotConnectedToInternet) {
		[MKInfoPanel showPanelInView:self.view 
							type:MKInfoPanelTypeError 
						   title:@"Could not fetch history!" 
						subtitle:@"Not connected to the Internet." 
					   hideAfter:3];
	} else {
		[MKInfoPanel showPanelInView:self.view 
								type:MKInfoPanelTypeError 
							   title:@"Could not fetch history!" 
							subtitle:nil
						   hideAfter:3];
	}
	if (graph) {
		[graph release];
		graph = nil;
	}
	graphHostingView.hostedGraph = nil;
	[self.view addSubview:noGraphLabel];
	[self.view setNeedsLayout];
}


#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return [ratesList count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index 
{
	
	Rate *r = [ratesList objectAtIndex:index];
	if(fieldEnum == CPTScatterPlotFieldX)
	{ 
		if ([xAxisValues count] > index) {
			NSNumber *num =  [self.xAxisValues objectAtIndex:index];
			return num;
		} else {
			return [NSNumber numberWithInt:0];
		}

	}
	else
	{
		//float floatNum = r.value;
		//floatNum *= 1000;
		//int intValue = (int) floatNum;
		//float decimal = floatNum - intValue;
		//if (decimal > 0.5) {
		//	intValue++;
		//}
		//floatNum = intValue /1000.0;
		//NSLog(@"Returning float %f", floatNum);
		return [NSNumber numberWithFloat:r.value];
	}
}

-(float) getMinY {
	Rate *r = [ratesList objectAtIndex:0];
	float min = r.value;
	int n = [ratesList count];
	for (int i=0; i<n; i++) {
		r =  [ratesList objectAtIndex:i];
		if (r.value < min) {
			min = r.value;
		}
	}
	return min;
}

-(float) getMaxY {
	Rate *r = [ratesList objectAtIndex:0];
	float max = r.value;
	int n = [ratesList count];
	for (int i=0; i<n; i++) {
		r =  [ratesList objectAtIndex:i];
		if (r.value > max) {
			max = r.value;
		}
	}
	return max;
}


@end
