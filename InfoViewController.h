//
//  InfoViewController.h
//  CAiOS
//
//  Created by Neville Smythe on 9/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "Constants.h"

@interface InfoViewController : UIViewController <UIWebViewDelegate>
{
	UIViewController *callingController;
	UIWebView * userManualView;
    
    UITextField* urlInput;
    UISegmentedControl* lang, * engType;
    UISegmentedControl* urlType;
    UIView * webControls;
    UITextField* statusField;
    
}

- (IBAction)closeView:(id)sender;
- (IBAction)langControl:(id)sender;
- (IBAction)engTypeControl:(id)sender;
- (IBAction)urlTypeControl:(id)sender;
- (IBAction)textFieldDidEndEditing:(id)sender;

@property (nonatomic, strong) UIViewController *callingController;
@property (nonatomic, strong) IBOutlet UIWebView * userManualView;
@property (nonatomic, strong) IBOutlet UITextField* urlInput;
@property (nonatomic, strong) IBOutlet UISegmentedControl* lang;
@property (nonatomic, strong) IBOutlet UISegmentedControl* engType;
@property (nonatomic, strong) IBOutlet UISegmentedControl* urlType;
@property (nonatomic, strong) IBOutlet UIView * webControls;
@property (nonatomic, strong) IBOutlet UITextField* statusField;


@end
