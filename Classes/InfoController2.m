//
//  InfoController2.m
//  ExRate
//
//  Created by MacBook Pro on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "InfoController2.h"

@implementation InfoController2
@synthesize titleLabel, subtitleLabel, versionLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Info";
//        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//        button.bounds = CGRectMake( 20, 7, 55, 30);    
//        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
//        UIImage *image = [UIImage imageNamed:@"black-back-button.png"];
//        UIImage *pressedImage = [UIImage imageNamed:@"bb-touch.png"];
//        [button setBackgroundImage:image forState:UIControlStateNormal];
//        [button setBackgroundImage:pressedImage forState:UIControlStateHighlighted];
//        button.backgroundColor = [UIColor clearColor];
//        [button setTitle:@"Back" forState:UIControlStateNormal];
//        button.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
//        button.titleLabel.textAlignment = UITextAlignmentCenter;
//        [button addTarget:self action:@selector(dismissAnimated) forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" 
                                                                        style:UIBarButtonItemStylePlain target:self action:@selector(dismissAnimated)];

        self.navigationItem.leftBarButtonItem = barButtonItem;
        [barButtonItem release];

    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void) dismissAnimated {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.titleLabel = nil;
    self.subtitleLabel = nil;
    self.versionLabel = nil;
}


-(void) dealloc {
    [super dealloc];
    [self.titleLabel release];
    [self.subtitleLabel release];
    [self.versionLabel release];
   }

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
