//
//  InfoController.m
//  ExRate
//
//  Created by Maja on 10/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "InfoController.h"


@implementation InfoController
@synthesize tableContent;

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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
	self.title = @"Info";
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.bounds = CGRectMake( 20, 7, 55, 30);    
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	UIImage *image = [UIImage imageNamed:@"black-back-button.png"];
	UIImage *pressedImage = [UIImage imageNamed:@"bb-touch.png"];
	[button setBackgroundImage:image forState:UIControlStateNormal];
	[button setBackgroundImage:pressedImage forState:UIControlStateHighlighted];
	button.backgroundColor = [UIColor clearColor];
	[button setTitle:@"Back" forState:UIControlStateNormal];
	button.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    button.titleLabel.textAlignment = UITextAlignmentCenter;
	[button addTarget:self action:@selector(dismissAnimated) forControlEvents:UIControlEventTouchUpInside];
	
	UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
	self.navigationItem.leftBarButtonItem = barButtonItem;
	[barButtonItem release];
	
	NSArray *arrTemp1 = [[NSArray alloc] initWithObjects:@"ExRate is an easy to use, simple and fast currency exchange rates viewer.\nIncludes about 120 currencies, currency conversion calculator and historical rates and graphs. ",nil];
	NSArray *arrTemp2 = [[NSArray alloc] initWithObjects:@"Ovdje ide nest o CorePlot",nil];
	NSDictionary *temp =[[NSDictionary alloc] initWithObjectsAndKeys:arrTemp1,@"About",arrTemp2, @"CorePlot",nil];
	self.tableContent =temp;
	[temp release];
	[arrTemp1 release];
	[arrTemp2 release];
	
	[super viewDidLoad];
}

-(void) dismissAnimated {
	[self dismissModalViewControllerAnimated:YES];
}
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark Table Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return [self.tableContent count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 	{
	NSArray *keys = [tableContent allKeys];
	return [keys objectAtIndex:section];
}
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	NSArray *keys = [tableContent allKeys];
	NSString *key = [keys objectAtIndex:section];
	NSArray *listData =[self.tableContent objectForKey:key];
	return [listData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"infoCell";
    
	NSArray *keys = [tableContent allKeys];
	NSString *key = [keys objectAtIndex:[indexPath section]];
	NSArray *listData =[self.tableContent objectForKey: key];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
    

	cell.textLabel.text = [listData objectAtIndex:[indexPath row]];
    cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    CGSize labelSize = [cell.textLabel.text sizeWithFont:cell.textLabel.font
                              constrainedToSize:cell.textLabel.frame.size
                                  lineBreakMode:cell.textLabel.lineBreakMode];
	cell.textLabel.frame = CGRectMake(
                             cell.textLabel.frame.origin.x, cell.textLabel.frame.origin.y, 
                             labelSize.width, labelSize.height);

	cell.textLabel.textColor = [UIColor darkGrayColor];
	cell.textLabel.numberOfLines = 0;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	return cell;
}
	

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
	[tableContent release];
    [super dealloc];
}


@end
