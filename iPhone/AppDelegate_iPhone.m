//
//  AppDelegate_iPhone.m
//  CAiOS
//
//  Created by Neville Smythe on 4/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyViewController.h"
//#import "MyDictionaryObject.h"
#import "AppDelegate_iPhone.h"

@implementation AppDelegate_iPhone

@synthesize window;
@synthesize myViewController;
//@synthesize myDictionaryObject;



#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.
    
        //setenv("CFNETWORK_DIAGNOSTICS", "3", 1);
	
	MyViewController *aViewController = [[MyViewController alloc] initWithNibName:@"MyViewController_iPhone" bundle:[NSBundle mainBundle]];
    [self setMyViewController:aViewController];
    self.window.rootViewController = self.myViewController;
	
	UIView *controllersView = [myViewController view];
    
    //the backview also needs to be extended
    //NSLog(@"window height for adjusting scrollview %f",self.window.bounds.size.height); //for 4.5inch phone
    if (self.window.bounds.size.height>480.0) {
        CGRect bRect = controllersView.frame;
        bRect.size.height = self.window.bounds.size.height - bRect.origin.y;
        [controllersView setFrame:bRect];
        bRect = myViewController.resultsField.frame;
        bRect.size.height = self.window.bounds.size.height - bRect.origin.y - 16 ; //bRect.size.height + 88;
        [myViewController.resultsField setFrame:bRect];
        bRect = myViewController.backView.frame;
        bRect.size.height = self.window.bounds.size.height - bRect.origin.y - 14 ; //bRect.size.height + 88;
        [myViewController.backView setFrame:bRect];
    
    }
	[window addSubview:controllersView];
    [window makeKeyAndVisible];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    NSArray * nibArray = [[NSBundle mainBundle] loadNibNamed:@"Numberpad_iPhone" owner:myViewController options:nil]; //do we need to retain??
    if ([nibArray count] > 0) {        
        myViewController.numberpad = [nibArray objectAtIndex:0];        
        [myViewController.numLettersField setInputView:myViewController.numberpad]; //this should be sufficient for retaining
        
        myViewController.numberpad.alpha = 0.9;// for iOS7 which overrides my xib setting 0.8 for <iOS7 ??
    }
    nibArray = [[NSBundle mainBundle] loadNibNamed:@"Alphapad_iPhone" owner:myViewController options:nil]; //do we need to retain??
    if ([nibArray count] > 0) {        
        myViewController.alphapad = [nibArray objectAtIndex:0];        
        [myViewController.patternField setInputView:myViewController.alphapad]; //this should be sufficient for retaining
        [[myViewController.alphapad.window viewWithTag:26] setHidden:YES];
        [myViewController.anagramField setInputView:myViewController.alphapad];
        
        myViewController.alphapad.alpha = 0.9;// for iOS7 which overrides my xib setting //doesnt work anyway?
    }
    
    [myViewController inputViewHack];
    //on first display of keyboard inout View in iOS9 an extra inputaccessory view is shown
    //this hack seems to fix;also needed when app bcomes active
    [myViewController.numberpad.window setHidden:YES];
    [myViewController.numLettersField becomeFirstResponder];
    [myViewController.numLettersField resignFirstResponder];
    [myViewController.numberpad.window setHidden:NO];
        
    myViewController.numberpad.window.alpha = 0.9;// for iOS7 which overrides my xib setting //doesn't work - maybe superview??
    myViewController.alphapad.window.alpha = 0.9;// for iOS7 which overrides my xib settin
    
    
    

    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    if (myViewController.prefsNeedSaving) 
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
    myViewController.prefsNeedSaving = NO;
    
    if (myViewController.myDictionaryManager.needsArchiving)
        [myViewController.myDictionaryManager archiveDictionaries];
    myViewController.myDictionaryManager.needsArchiving = NO;


}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    //NSLog(@"app will become will enter foreground");
    [myViewController.myDictionaryManager updateDictionaryArray]; // in case user has added dictionary
    dispatch_async(myViewController.backgroundQueue, ^(void) {
        [self.myViewController.myDictionaryManager downloadServeDictArrayAsynch];
    });

}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
    
    if (myViewController.prefsNeedSaving) 
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
    myViewController.prefsNeedSaving = NO;
    
    if (myViewController.myDictionaryManager.needsArchiving)
        [myViewController.myDictionaryManager archiveDictionaries];
    myViewController.myDictionaryManager.needsArchiving = NO;


}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


@end
