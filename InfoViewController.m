//
//  InfoViewController.m
//  CAiOS
//
//  Created by Neville Smythe on 9/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InfoViewController.h"
#import "myViewController.h"
//#import "AppDelegate_iPhone.h" //actual call will be the device specific code presumably


@interface InfoViewController ()

@end

@implementation InfoViewController

@synthesize callingController, userManualView, statusField;
@synthesize webControls,lang,urlType,urlInput, engType;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
 */

- (void)viewDidLoad
{
    [super viewDidLoad];
	CGRect aRect;
	float hh = self.callingController.view.bounds.size.height;
    
    aRect = CGRectMake(0, hh, self.callingController.view.bounds.size.width, hh-100);
	
	[self.view setFrame:aRect];
    	
	[lang addTarget:self action:@selector(langControl:)
               forControlEvents:UIControlEventValueChanged];
    [urlType addTarget:self action:@selector(urlTypeControl:)
                forControlEvents:UIControlEventValueChanged];
    
    [self fixImagesOfSegmentedControlForiOS7:lang];
    [self fixImagesOfSegmentedControlForiOS7:urlType];
    [self fixImagesOfSegmentedControlForiOS7:engType];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.userManualView.delegate = nil;
    self.userManualView = nil;
    self.callingController = nil;
    self.statusField = nil;
    
    self.urlInput = nil;
    self.lang = nil;
    self.urlType = nil;
    self.webControls = nil;

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)fixImagesOfSegmentedControlForiOS7:(UISegmentedControl*)theControl
{
    NSInteger deviceVersion = [[UIDevice currentDevice] systemVersion].integerValue;
    
    if(deviceVersion < 7) // If this is not an iOS 7 device, we do not need to perform these customizations.
        return;
    
    for(int i=0;i<theControl.numberOfSegments;i++)
    {
        UIImage* img = [theControl imageForSegmentAtIndex:i];
        UIImage* goodImg = [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        // clone image with different rendering mode
        [theControl setImage:goodImg forSegmentAtIndex:i];
    }
}

/*
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    //return (UIInterfaceOrientationMaskAll);
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown);
}
*/
- (BOOL)shouldAutorotate
{
    
    return YES;
}


-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)
request navigationType:(UIWebViewNavigationType)navigationType {
    
    if ((navigationType == UIWebViewNavigationTypeLinkClicked) && (![[request URL] isFileURL])) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
    return YES;
}

- (void)closeView:(id)sender {
    [callingController performSelector:@selector(dismissInfoView)];
}

- (void)langControl:(id)sender{
    int selSegment = (int)[(UISegmentedControl*)sender selectedSegmentIndex];
    [callingController performSelector:@selector(putLang:) withObject:[NSNumber numberWithInt:selSegment]];
    
}

- (void)engTypeControl:(id)sender{
    int selSegment = (int)[(UISegmentedControl*)sender selectedSegmentIndex];
    [callingController performSelector:@selector(putEngType:) withObject:[NSNumber numberWithInt:selSegment]];
    
}


- (void)urlTypeControl:(id)sender{
    int selSegment = (int)[(UISegmentedControl*)sender selectedSegmentIndex];
    [callingController performSelector:@selector(putURLType:) withObject:[NSNumber numberWithInt:selSegment]];
   
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{ 
	
    [theTextField resignFirstResponder];
    if ([urlType selectedSegmentIndex] == kUser){
        [callingController performSelector:@selector(putUserURL:) withObject:[urlInput text]];
    }
    
	return YES;
}

- (IBAction)textFieldDidEndEditing:(id)sender{    
    [self.userManualView 
          loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[urlInput text]]]];    
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[statusField setText:@"loading..."];
	//NSLog(@"loading...");
	statusField.hidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{	statusField.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{	[statusField setText:[error localizedDescription]];
	//NSLog(@"failed load %@",[error localizedDescription]);
}




@end
