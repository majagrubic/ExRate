    //
//  CurrencyChooserController.m
//  ExRate
//
//  Created by Maja on 10/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CurrencyChooserController.h"
#import "Currency.h"
#import "CurrencyController.h"
#import "CurrencyCell.h"
#define searchBarHeight 36


@implementation CurrencyChooserController
@synthesize searchBar, tableView, currencyList;
@synthesize checkedIndexPath;
@synthesize currController;
@synthesize searchResults;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

-(id) init {
	self = [super init];
    if (self) {
        self.title = @"ExRate";
		CGRect bounds = [[UIScreen mainScreen] bounds];

		searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, searchBarHeight)];
		searchBar.barStyle = UIBarStyleBlack;
		searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
		searchBar.delegate = self;
		[self.view addSubview:searchBar];
		
		CGRect frame = CGRectMake(0, 36, bounds.size.width, bounds.size.height - 64 - searchBarHeight);
		self.tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
		[self.tableView setDelegate:self];
		[self.tableView setDataSource:self];
		[self.tableView setRowHeight:rowHeight];
		[self.view addSubview:self.tableView];
	    [self.tableView release];
		
		self.checkedIndexPath = [[NSIndexPath alloc] initWithIndex:-1];
		searchResults = [[NSMutableArray	alloc] init];
		searching = NO;
		
    }
    return self;

}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	//checkedIndexPath = [[NSIndexPath indexPathWithIndex:-1] retain];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] 
									 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
									 target:self
									 action:@selector(cancel)];
	
	[[self navigationItem] setLeftBarButtonItem:cancelButton];
	
	[[self navigationItem] setLeftBarButtonItem:cancelButton];
	
	[cancelButton release];
	
}

-(void) done 
{
	[self.currController initHeaderView];
	[self.currController.tableView reloadData];
	[self dismissModalViewControllerAnimated:YES];

}
- (void)cancel
{
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (searching) return [searchResults count];
	return [currencyList count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"currencyCell";
	int row = [indexPath row];
	
	CurrencyCell *cell = (CurrencyCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
        // No reusable cell was available, so we create a new cell and configure its subviews.
        cell = [[[CurrencyCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier] autorelease];
	}
	Currency *currency;
	if (searching) {
		if ([searchResults count] > row) {
			currency = [searchResults objectAtIndex:row];
		}
		else {
			currency = [currencyList objectAtIndex:row];

			[self.searchBar resignFirstResponder];
		}
	} else {
		currency = [currencyList objectAtIndex:indexPath.row];
	}
	cell.titleLabel.text = currency.code;
	cell.subtitleLabel.text = currency.description;

	NSString *suffix = [currency.code substringToIndex:2];
	suffix = [suffix lowercaseString];
	NSString *imagePath = [NSString stringWithFormat:@"flag_%@.png",suffix];
    UIImage *flagImage = [UIImage imageNamed:imagePath];
	if (flagImage == nil) {
		flagImage = [UIImage imageNamed:@"flag_null.png"];
	}
	cell.cImage.image =flagImage;		
	if ([self.checkedIndexPath compare:indexPath] == NSOrderedSame) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (searching && [searchResults count] > 0) {
		self.currController.baseCurrency = [searchResults objectAtIndex:[indexPath row]];
	} else {
		self.currController.baseCurrency = [currencyList objectAtIndex:[indexPath row]];
	}
	self.checkedIndexPath = indexPath;
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
	[self performSelector:@selector(done) withObject:nil afterDelay:0.5];
}

- (NSIndexPath *)tableView :(UITableView *)theTableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {	
	return indexPath;
}

#pragma mark -
#pragma mark UISearchBar
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
		[self.searchBar setShowsCancelButton:YES animated:YES];
		searching = YES;
		[searchResults removeAllObjects];
		self.tableView.scrollEnabled = NO;
}

- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
	
	if ([searchResults count] > 0) {
		//Remove all objects first.
		[searchResults removeAllObjects];
	}
	
	if ([self.searchBar isFirstResponder]) {
		if([searchText length] >0) {
			searching = YES;
			self.tableView.scrollEnabled = YES;
			[self searchTableView];
		}
		else {
			searching = NO;
		}
	} else {
		//'clear' button was tapped
		searching = NO;
		self.tableView.scrollEnabled = NO;
	}
	[self.tableView reloadData];
	
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.text=@"";
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.searchBar resignFirstResponder];
	searching = NO;
	self.tableView.scrollEnabled = YES;
	[self.tableView reloadData];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)sBar {
	[sBar resignFirstResponder];
	for (UIView *possibleButton in sBar.subviews)
	{
		if ([possibleButton isKindOfClass:[UIButton class]])
		{
			UIButton *cancelButton = (UIButton*)possibleButton;
			cancelButton.enabled = YES;
			break;
		}
	}
	
	[self searchTableView];
}

- (void) searchTableView {
	
	NSString *searchText = searchBar.text;	
	if (searchText.length == 0) return;
	for (Currency *curr in currencyList)
	{
		NSRange codeResultsRange = [curr.code rangeOfString:searchText options:NSCaseInsensitiveSearch];
		NSRange descResultsRange = [curr.description rangeOfString:searchText options:NSCaseInsensitiveSearch];
		
		if (codeResultsRange.length > 0 || descResultsRange.length > 0) {
			if (![searchResults containsObject:curr]) {
				[searchResults addObject:curr];
			}
		}
	}
}



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[searchBar release];
	[tableView release];
	[currencyList release];
	[checkedIndexPath release];
	[currController release];
	[searchResults release];
    [super dealloc];
}


@end
