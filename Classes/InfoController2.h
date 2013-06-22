//
//  InfoController2.h
//  ExRate
//
//  Created by MacBook Pro on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoController2 : UIViewController {

    UILabel *titleLabel;
    UILabel *subtitleLabel;
    UILabel *versionLabel;

}

@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, retain) IBOutlet UILabel *versionLabel;

-(void) dismissAnimated;
@end
