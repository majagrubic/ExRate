//
//  InfoController.h
//  ExRate
//
//  Created by Maja on 10/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface InfoController : UITableViewController {
	NSDictionary *tableContent;
}

@property (nonatomic, retain) NSDictionary *tableContent;

-(void) dismissAnimated;

@end
