//
//  ExRateAppDelegate.m
//  ExRate
//
//  Created by Maja on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ExRateAppDelegate.h"
#import "CurrencyController.h"
#import "ParseOperation.h"
#import "Currency.h"
#import "MKInfoPanel.h"
#import "Reachability.h"

#import <CFNetwork/CFNetwork.h>

#pragma mark ExRateAppDelegate () 

// forward declarations
@interface ExRateAppDelegate ()

@property (nonatomic, retain) NSURLConnection *feedConnection;
@property (nonatomic, retain) NSMutableData *currenciesData;    // the data returned from the NSURLConnection
@property (nonatomic, retain) NSOperationQueue *parseQueue;     // the queue that manages our NSOperation for parsing earthquake data

- (void)addCurrenciesToList:(NSArray *)currencies;
- (void)handleError:(NSError *)error;
@end


@implementation ExRateAppDelegate


@synthesize window = _window;
@synthesize feedConnection;
@synthesize currenciesData;
@synthesize parseQueue;

@synthesize cController;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
	CGRect rect = [[UIScreen mainScreen] bounds];
    UIWindow *window = [[UIWindow alloc] initWithFrame:rect];
	cController = [[CurrencyController alloc] init];
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:cController];
	nav.navigationBar.barStyle = UIBarStyleBlack;
	nav.title = @"Title";
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	internetReach = [[Reachability reachabilityForInternetConnection] retain];
	[internetReach startNotifier]; 
	[self updateInterfaceWithReachability: internetReach];
	
	if ([self shouldFetchData]) {
		[self fetchData:YES];
	} else {
		didUpdate = NO;
		
		NSArray *currencies = [self loadDataSavedLocally];
		if (currencies != nil) 
		{
			[self addCurrenciesToList:currencies];
			[currencies release];
		}
	}
	
	// Create the array of UIViewControllers
	[window addSubview:nav.view];
	[window makeKeyAndVisible];
	[self setWindow:window];
	
	[window release];
   	return YES;
}

-(void) applicationWillTerminate:(UIApplication *)application {
	NSLog(@"Will terminate");
	NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
	NSData *myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:cController.baseCurrency];
	[currentDefaults setObject:myEncodedObject forKey:@"baseCurrency"];
    NSArray *favs = [NSArray arrayWithObjects:cController.baseCurrency, nil];
    NSData *favsData = [NSKeyedArchiver archivedDataWithRootObject:favs];
	[currentDefaults setObject:favsData forKey:@"favs"];

}

-(void) applicationDidEnterBackground:(UIApplication *)application {
	NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
	NSData *myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:cController.baseCurrency];
	[currentDefaults setObject:myEncodedObject forKey:@"baseCurrency"];
    NSArray *favs = [NSArray arrayWithObjects:cController.baseCurrency, nil];
    NSData *favsData = [NSKeyedArchiver archivedDataWithRootObject:favs];
	[currentDefaults setObject:favsData forKey:@"favs"];

}


-(BOOL) shouldFetchData {
	NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
	
	// assign values
	NSString *dateStr = [currentDefaults stringForKey:@"Date"];
	if (dateStr == nil || ([dateStr length] == 0)) {
		return YES;
	}
		
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"yyyyMMdd hh:mm:ss"];
	NSDate *dateLastUpdate = [dateFormat dateFromString:dateStr];  
	NSDate *dateNow = [NSDate date];
	[dateFormat release];
	
	NSCalendar* calendar = [NSCalendar currentCalendar];	
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
	NSDateComponents* last = [calendar components:unitFlags fromDate:dateLastUpdate];
	NSDateComponents* now = [calendar components:unitFlags fromDate:dateNow];

	if ([last day] == [now day] && [last month] == [now month] && [last year]==[now year]) {
		//lastUpdated is in the past from now
		return NO;
	}
	return YES;
}

-(void) saveDate {
	// get paths from root direcory
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
	NSDate *dateNow = [NSDate date];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setLocale:[NSLocale currentLocale]];
	[formatter setDateFormat:@"yyyyMMdd hh:mm:ss"];
	NSString *stringFromDate = [formatter stringFromDate:dateNow];
	[formatter release];
	[currentDefaults setObject:stringFromDate forKey:@"Date"];
}


-(NSString*) lastUpdated {
	NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
	return [currentDefaults stringForKey:@"Date"];
}

-(NSArray*) loadDataSavedLocally {
	
	NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
	NSData *dataRepresentingSavedArray = [currentDefaults objectForKey:@"currencyArray"];
	NSMutableArray *currenciesArray = nil;
	if (dataRepresentingSavedArray != nil)
	{
		NSArray *oldSavedArray = [NSKeyedUnarchiver unarchiveObjectWithData:dataRepresentingSavedArray];
		if (oldSavedArray != nil)
			currenciesArray = [[NSMutableArray alloc] initWithArray:oldSavedArray];
		else
			currenciesArray =  [[NSMutableArray alloc] init];
	}
	return currenciesArray;
}

-(void) fetchData:(BOOL)showHUD {
	didUpdate = YES;
	static NSString *feedURLString = @"http://gw.udovicic.com/exrate/get.php";
	NSURLRequest *currencyURLRequest =
	[NSURLRequest requestWithURL:[NSURL URLWithString:feedURLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
	self.feedConnection = [[[NSURLConnection alloc] initWithRequest:currencyURLRequest delegate:self] autorelease];
	NSAssert(self.feedConnection != nil, @"Failure to create URL connection.");
	if (showHUD) {
		HUD = [[MBProgressHUD showHUDAddedTo:self.cController.navigationController.view animated:YES] retain];
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	if (parseQueue) {
		[parseQueue release];
		parseQueue = nil;
	}
	parseQueue = [NSOperationQueue new];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(addCurrencies:)
												 name:kAddCurrenciesNotif
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(currenciesError:)
												 name:kCurrenciesErrorNotif
											   object:nil];
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
  
	expectedLength = [response expectedContentLength];
	currentLength = 0;
	if (HUD != nil) HUD.mode = MBProgressHUDModeDeterminate;
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (([httpResponse statusCode]/100) == 2) { //&& [[response MIMEType] isEqual:@"application/atom+xml"]) {
        self.currenciesData = [NSMutableData data];
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
	if(HUD != nil) HUD.progress = currentLength / (float)expectedLength;
    [currenciesData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
   if (HUD != nil) [HUD hide:YES];
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
        // otherwise handle the error generically
        [self handleError:error];
    }
    self.feedConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if (HUD != nil) {
		HUD.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]] autorelease];
		HUD.mode = MBProgressHUDModeCustomView;
		[HUD hide:YES afterDelay:0.5];
	}
	
	self.feedConnection = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;   
    
	ParseOperation *parseOperation = [[ParseOperation alloc] initWithData:self.currenciesData];
    [self.parseQueue addOperation:parseOperation];
    [parseOperation release];   // once added to the NSOperationQueue it's retained, we don't need it anymore
    
	self.currenciesData = nil;
	[self saveDate];
}

// Handle errors in the download by showing an alert to the user. This is a very
// simple way of handling the error, partly because this application does not have any offline
// functionality for the user. Most real applications should handle the error in a less obtrusive
// way and provide offline functionality to the user.
//
- (void)handleError:(NSError *)error {
	static BOOL showAlert = YES;
	if ([error code] == kCFURLErrorNotConnectedToInternet && showAlert) {
		[MKInfoPanel showPanelInView:[self.cController view] 
							type:MKInfoPanelTypeError 
							title:@"Network Failure!" 
							subtitle:@"Not connected to the Internet." 
						   hideAfter:3];
		
	} else if (showAlert){
		[MKInfoPanel showPanelInView:[self.cController view] 
								type:MKInfoPanelTypeError 
							   title:@"Could not fetch exchange rates!" 
							subtitle:nil 
						   hideAfter:3];
	}
	
	NSArray *array = [self loadDataSavedLocally];
	if (array != nil) {
		[self addCurrenciesToList:array];
	} else {
		self.cController.showingEmptyView = YES;
		[self.cController showEmptyView];
	}
}

- (void)addCurrencies:(NSNotification *)notif {
    assert([NSThread isMainThread]);
	NSArray *currencies = [[notif userInfo] valueForKey:kCurrencyResultsKey];
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:currencies] forKey:@"currencyArray"];

    [self addCurrenciesToList:currencies];
}

// Our NSNotification callback from the running NSOperation when a parsing error has occurred
//
- (void)currenciesError:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    
    [self handleError:[[notif userInfo] valueForKey:kCurrenciesMsgErrorKey]];
}

- (void)addCurrenciesToList:(NSArray *)currencies {
	if (currencies == nil || [currencies count] == 0) {
		return;
	}
    // insert the currencies into our rootViewController's data source (for KVO purposes)
	[self.cController insertCurrencies:currencies];
	if ([self.cController reloading])
		[self.cController doneLoadingTableViewData];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
	if (HUD) {
		// Remove HUD from screen when the HUD was hidded
		[HUD removeFromSuperview];
		[HUD release];
		HUD = nil;
	}
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kAddCurrenciesNotif object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kCurrenciesErrorNotif object:nil];
	
    [_window release];
	[feedConnection release];
	[currenciesData release];
	[parseQueue release];
	[cController release];	
	
    [super dealloc];
}

-(void) updateInterfaceWithReachability:(Reachability*) curReach {
	if(curReach == internetReach)
	{	
		NetworkStatus netStatus = [curReach currentReachabilityStatus];
		BOOL connectionRequired= [curReach connectionRequired];
		switch (netStatus)
		{
			case NotReachable:
			{
				//Minor interface detail- connectionRequired may return yes, even when the host is unreachable.  We cover that up here...
				connectionRequired= NO; 
			//	[self.cController showEmptyView];
				break;
			}
				
			case ReachableViaWWAN:
			{
				if (self.cController.showingEmptyView) {
					[self fetchData:YES];
				}
				[self.cController showView];
				break;
			}
			case ReachableViaWiFi:
			{
				if (self.cController.showingEmptyView) {
					[self fetchData:YES];
				}
				[self.cController showView];
				break;
			}
		}
		if(connectionRequired)
		{
			
		}
		
	}
}

- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateInterfaceWithReachability: curReach];
}
@end
