//
//  FavoritesController.m
//  ExRate
//
//  Created by Maja on 11/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FavoritesController.h"


@implementation FavoritesController

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

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

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
    [super dealloc];
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


@end
