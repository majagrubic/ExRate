//
//  CurrencyController.m
//  ExRate
//
//  Created by Maja on 10/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CurrencyController.h"
#import "HistoryController.h"
#import "Currency.h"
#import "CurrencyChooserController.h"
#import "ExRateAppDelegate.h"
#import "InfoController2.h"
#import "CurrencyCell.h"

@interface CurrencyController()
-(NSString*) calculateCurrencyValue:(Currency *)currency;

@end


@implementation CurrencyController


#pragma mark -
#pragma mark Initialization
#define rowHeight 60

@synthesize textFieldNormal;
@synthesize currencyList;
@synthesize tableView;
@synthesize baseCurrency;
@synthesize numberFormatter;
@synthesize reloading = _reloading;
@synthesize showingEmptyView;
@synthesize headerView;

- (id)init {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super init];
    if (self) {
        self.title = @"ExRate";
		
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Inverse" 
                                                                          style:UIBarButtonItemStylePlain target:self action:@selector(inverse)];
        [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
        [barButtonItem release];

		
		UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *modalButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
        [self.navigationItem setRightBarButtonItem:modalButton animated:YES];
        [modalButton release];
		
		inverse = NO;
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSData *myEncodedObject = [defaults objectForKey:@"baseCurrency"];
		Currency* curr = (Currency*)[NSKeyedUnarchiver unarchiveObjectWithData: myEncodedObject];
		if (curr != nil) {
			self.baseCurrency = curr;
		}
		
		if (self.baseCurrency == nil) {
			Currency *curr = [[Currency alloc] init];
			curr.code = @"USD";
			curr.description = @"American Dollar";
			self.baseCurrency = curr;
			[curr release];
		} 
		self.numberFormatter = [[NSNumberFormatter alloc] init];
		[self.numberFormatter setPositiveFormat:@"##0.00"];
		[self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[numberFormatter setLocale:[NSLocale currentLocale]];
		[self initHeaderView];
		
		CGRect bounds = [[UIScreen mainScreen] bounds];
		CGRect frame = CGRectMake(0, rowHeight, bounds.size.width, bounds.size.height - rowHeight- 64);
		self.tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
		[self.tableView setDelegate:self];
		[self.tableView setDataSource:self];
		[self.tableView setRowHeight:rowHeight];
		[self.view addSubview:self.tableView];
	    [self.tableView release];
		
		if (_refreshHeaderView == nil) {
			
			EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
			view.delegate = self;
			[self.tableView addSubview:view];
			_refreshHeaderView = view;
			[view release];
			_reloading = NO;
			
		}
		keyboardToolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 480, 420, 40)] autorelease];
		[self.view addSubview:keyboardToolbar];
		//  update the last update date
		[_refreshHeaderView refreshLastUpdatedDate];
		
		emptyView = [[TKEmptyView alloc] initWithFrame:self.view.bounds 
										emptyViewImage:TKEmptyViewImageMale
												 title:@"Exchange rates cannot be displayed"
											  subtitle:@"No Internet connection"];
		
		emptyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;		
		
	}
    return self;
}


-(void) inverse {
	inverse = !inverse;
	[self.tableView reloadData];
}


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	self.currencyList = [NSMutableArray array];
    [self addObserver:self forKeyPath:@"currencyList" options:0 context:NULL];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

	// add observer for the respective notifications (depending on the os version)
	
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(keyboardDidShow:) 
													 name:UIKeyboardDidShowNotification 
												   object:nil];		
	
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(keyboardWillShow:) 
													 name:UIKeyboardWillShowNotification 
												   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											   selector:@selector(updateTable:) name:UITextFieldTextDidChangeNotification object:nil];    
	[self.tableView reloadData];
}



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

-(void) showInfo {
	InfoController2 *controller = [[InfoController2 alloc] initWithNibName:@"InfoController2" bundle:nil];
	    
	UINavigationController *newNavController = [[UINavigationController alloc]
	                                                initWithRootViewController:controller];
	newNavController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	newNavController.navigationBar.barStyle = UIBarStyleBlack;
	[self presentModalViewController:newNavController animated:YES];
}

-(void) showCurrencyChooser:(id) sender {
	CurrencyChooserController *controller = [[CurrencyChooserController alloc] init];
	controller.currencyList = self.currencyList;
	controller.currController = self;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	UINavigationController *newNavController = [[UINavigationController alloc]
                                                initWithRootViewController:controller];
	newNavController.navigationBar.barStyle = UIBarStyleBlack;
	[self presentModalViewController:newNavController animated:YES];	
}


#pragma mark -
#pragma mark KVO support

- (void)insertCurrencies:(NSArray *)currencies {
    [self willChangeValueForKey:@"currencyList"];
	[self.currencyList removeAllObjects];
    [self.currencyList addObjectsFromArray:currencies];
    [self didChangeValueForKey:@"currencyList"];
	//[self.tableView reloadData];
}

// listen for changes to the currency list coming from our app delegate.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    [self.tableView reloadData];
}



#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.currencyList count];
}


- (void) initHeaderView {
	if (headerView != nil) {
		[headerView release];
		headerView = nil;
	}
	headerView = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    headerView.frame = CGRectMake(0,0, 320,rowHeight);
	[headerView setBackgroundColor:[UIColor lightGrayColor]];
	[headerView addTarget:self action:@selector(showCurrencyChooser:) forControlEvents:UIControlEventTouchUpInside];
	
    CGRect imageRect = CGRectMake(5.0f, 2.5f, 60.0f, 55.0f);
	UIImageView *cImage = [[UIImageView alloc] initWithFrame:imageRect];
	NSString *suffix = [[baseCurrency code] substringToIndex:2];
	suffix = [suffix lowercaseString];
	NSString *imagePath = [NSString stringWithFormat:@"flag_%@.png",suffix];
	[cImage setImage:[UIImage imageNamed:imagePath]];
	
	CGRect titleRect = CGRectMake(70.0f, 5.0, 140.0f, 27.5f);
	UILabel	*titleLabel = [[UILabel alloc] initWithFrame:titleRect];
	[titleLabel setBackgroundColor:[UIColor clearColor]];
	[titleLabel setFont: [UIFont fontWithName:@"STHeitiTC-Medium" size:16.0f]];
	[titleLabel setText:[baseCurrency code]];
	
	CGRect subtitleRect = CGRectMake(70.0f, 32.5f, 140.0f, 22.5f);
	UILabel	*subtitleLabel = [[UILabel alloc] initWithFrame:subtitleRect];
	[subtitleLabel setFont: [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0f]];
	[subtitleLabel setTextColor:[UIColor darkGrayColor]];
	[subtitleLabel setBackgroundColor:[UIColor clearColor]];
	if ([baseCurrency description] != nil) {
		[subtitleLabel setText:[baseCurrency description]];
	} 
	
	[headerView addSubview:cImage];
	[headerView addSubview:titleLabel];
	[headerView addSubview:subtitleLabel];
	[headerView addSubview:[self initTextField]];
	
	[cImage release];
	[titleLabel release];
	[subtitleLabel release];
	
	[self.view addSubview:headerView];
	
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"currencyCell";
	
	CurrencyCell *cell = (CurrencyCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
        // No reusable cell was available, so we create a new cell and configure its subviews.
		cell = [[[CurrencyCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier] autorelease];
	}
    
   	Currency *currency = [currencyList objectAtIndex:indexPath.row];
	// Set the relevant data for each subview in the cell.
    cell.titleLabel.text = [currency code];
    cell.subtitleLabel.text = currency.description;
    cell.destCurrencyLabel.text = [NSString stringWithFormat:@"%@ %@", [textFieldNormal text], (inverse ? currency.code : baseCurrency.code)];
	cell.srcCurrencyLabel.text = [self calculateCurrencyValue:currency];
	NSString *suffix = [[currency code] substringToIndex:2];
	suffix = [suffix lowercaseString];
	NSString *imagePath = [NSString stringWithFormat:@"flag_%@.png",suffix];
	UIImage *flagImage = [UIImage imageNamed:imagePath];
	if (flagImage == nil) {
		flagImage = [UIImage imageNamed:@"flag_null.png"];
	}
	cell.cImage.image =flagImage;	
	currency.imagePath = imagePath;
	
	cell.selected = NO;
	
    return cell;
}

-(NSString *) calculateCurrencyValue:(Currency*) currency {
	NSString *format = [NSString stringWithString:@"%@ %@"];
	NSString *formattedNumberString;
	CGFloat amount = [textFieldNormal.text floatValue];
	if ([baseCurrency.code isEqualToString:@"USD"] && !inverse) {
		formattedNumberString = [self.numberFormatter stringFromNumber:[NSNumber numberWithFloat:(amount*currency.value)]];
		return [NSString stringWithFormat:format, formattedNumberString, [currency code]];	
	} else if ([baseCurrency.code isEqualToString:@"USD"]) {
		formattedNumberString = [self.numberFormatter stringFromNumber:[NSNumber numberWithFloat:(amount*currency.valueToDollars)]];
		return [NSString stringWithFormat:format, formattedNumberString, @"USD"];	
	} else if (!inverse) {
		CGFloat value = baseCurrency.valueToDollars * currency.value * amount;
		formattedNumberString = [self.numberFormatter stringFromNumber:[NSNumber numberWithFloat:value]];
		return [NSString stringWithFormat:format, formattedNumberString, currency.code];
	} else {
		CGFloat value = currency.valueToDollars * baseCurrency.value * amount;
		formattedNumberString = [self.numberFormatter stringFromNumber:[NSNumber numberWithFloat:value]];
		return [NSString stringWithFormat:format, formattedNumberString, baseCurrency.code];
	}
}


- (UITextField *)initTextField {
	CGRect frame = CGRectMake(215.0, 5.0f, 101.0f, 50.0f);	
	textFieldNormal = [[UITextField alloc] initWithFrame:frame];
	
	textFieldNormal.borderStyle = UITextBorderStyleLine;
	textFieldNormal.textColor = [UIColor blackColor];
	textFieldNormal.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:16.0f];
	textFieldNormal.backgroundColor = [UIColor whiteColor];
	textFieldNormal.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	textFieldNormal.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
	textFieldNormal.textAlignment = UITextAlignmentRight;
	
	textFieldNormal.keyboardType = UIKeyboardTypeDecimalPad;	// use the default type input method (entire keyboard)
	textFieldNormal.returnKeyType = UIReturnKeyDone;
		
			
	textFieldNormal.delegate = self;	
		
		// Add an accessibility label that describes what the text field is for.
	[textFieldNormal setAccessibilityLabel:NSLocalizedString(@"Enter Currency", @"")];
	
	NSString *formattedNumberString = [self.numberFormatter stringFromNumber:[NSNumber numberWithFloat:1.00]];
	[textFieldNormal setText:formattedNumberString];
	
	//[texFieldNormal addTarget:self action:@selector(updateTable:) forControlEvents:UITextFieldTextDidChange];
	
	return textFieldNormal;
}

- (void)keyboardDidShow:(NSNotification *)note {
	
}

- (void)keyboardWillShow:(NSNotification *)note {
	NSDictionary *userInfo = [note userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
	
    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    CGFloat keyboardTop = keyboardRect.origin.y;

    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    
   // keyboardToolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, keyboardTop - 40, keyboardRect.size.width, 40)] autorelease];
	[keyboardToolbar setBarStyle:UIBarStyleBlackTranslucent];
	//[keyboardToolbar sizeToFit];
	
	UIBarButtonItem *flexButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	UIBarButtonItem *doneButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButton:)];
	
	NSArray *itemsArray = [NSArray arrayWithObjects:flexButton, doneButton, nil];
	
	[flexButton release];
	[doneButton release];
	[keyboardToolbar setItems:itemsArray];
	[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
	keyboardToolbar.frame = CGRectMake(0, keyboardTop - 40, keyboardRect.size.width, 40);
	[UIView commitAnimations];	
}


- (void)doneButton:(id)sender {
	[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
	keyboardToolbar.frame = CGRectMake(0, 480, 420, 40);
    [UIView commitAnimations];
	
    [self.textFieldNormal resignFirstResponder];
	if ([self.textFieldNormal.text length] == 0 ) {
		self.textFieldNormal.text = [self.numberFormatter stringFromNumber:[NSNumber numberWithFloat:1.00]];
	}
}

-(void) showEmptyView {
	button.enabled = NO;
	[self.view addSubview:emptyView];
	[self.view setNeedsLayout];
}

-(void) showView {
	button.enabled = YES;
	if (showingEmptyView) {
		[emptyView removeFromSuperview];
	}
	showingEmptyView = NO;
	[self.view setNeedsLayout];
}


#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[textFieldNormal setText:@""];
}


-(void) updateTable:(id)sender {
	int len = textFieldNormal.text.length;
	if (len == 0) return;
	[self.tableView reloadData];
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	HistoryController *controller = [[HistoryController alloc] init];
	Currency *curr = [currencyList objectAtIndex:[indexPath row]];
	if (inverse) {
		controller.srcCurrency = curr.code;
		controller.destCurrency = baseCurrency.code;
	} else{
		controller.srcCurrency = baseCurrency.code;
		controller.destCurrency = curr.code;
	}
	
	
    [[self navigationController] pushViewController:controller
                                           animated:YES];
	[controller release];

}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

-(void)viewDidUnload {
	NSLog(@"View did unload");
    [super viewDidUnload];
    self.currencyList = nil;
	//[headerView release];
//	headerView = nil;
   [self removeObserver:self forKeyPath:@"currencyList"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	_refreshHeaderView=nil;
}



- (void)dealloc {
	[baseCurrency release];
	[emptyView release];
	[textFieldNormal release];
	[headerView release];
	[currencyList release];
	[numberFormatter release];
	[button release];
	[keyboardToolbar release];
	_refreshHeaderView = nil;
	[tableView release];
    [super dealloc];
}
#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	ExRateAppDelegate *appDelegate = (ExRateAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate fetchData:NO];
	_reloading = YES;
	
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
	
}


#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{	
	
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
	
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
}


#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
	[self reloadTableViewDataSource];
//	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	ExRateAppDelegate *appDelegate = (ExRateAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setLocale:[NSLocale currentLocale]];
	[formatter setDateFormat:@"yyyyMMdd hh:mm:ss"];
	NSString *lastUpdated = [appDelegate lastUpdated];
	NSDate *lastUpdateDate = [formatter dateFromString:lastUpdated];
	[formatter release];
	return lastUpdateDate;  // should return date data source was last changed
}


@end

