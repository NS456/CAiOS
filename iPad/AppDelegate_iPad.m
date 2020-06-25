//
//  AppDelegate_iPad.m
//  CAiOS
//
//  Created by Neville Smythe on 4/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate_iPad.h"
#import "MyViewController.h"
//#import "MyDictionaryObject.h"

@implementation AppDelegate_iPad

@synthesize window;
@synthesize myViewController;
//@synthesize myDictionaryObject;



#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.
	
	MyViewController *aViewController = [[MyViewController alloc] initWithNibName:@"MyViewController_iPad" bundle:[NSBundle mainBundle]];
    [self setMyViewController:aViewController];
    self.window.rootViewController = self.myViewController;
		
    [window makeKeyAndVisible];
    
    
    NSArray * nibArray = [[NSBundle mainBundle] loadNibNamed:@"Numberpad_iPad" owner:myViewController options:nil];
    if ([nibArray count] > 0) {        
        myViewController.numberpad = [nibArray objectAtIndex:0];        
        
    }
    nibArray = [[NSBundle mainBundle] loadNibNamed:@"Alphapad_iPad" owner:myViewController options:nil]; 
    if ([nibArray count] > 0) {        
        myViewController.alphapad = [nibArray objectAtIndex:0];        
        [[myViewController.alphapad.window viewWithTag:26] setHidden:YES];


        
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];

    }
    //following cannot be done in myViewController viewdidload, because pads not yet set then
    
    [myViewController.anagramField setInputView:myViewController.alphapad];
   [myViewController.patternField setInputView:myViewController.alphapad];
    [myViewController.numLettersField setInputView:myViewController.numberpad];
    
    [myViewController inputViewHack];
        
    //myViewController.numberpad.window.alpha = 0.9;// for iOS7 which overrides my xib setting //doesn't work - maybe superview??
    //myViewController.alphapad.window.alpha = 0.9;// for iOS7 which overrides my xib settin
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    [myViewController inputViewHack];

}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    
    [myViewController inputViewHack];

    
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
    //also update serverDictionaryArray
    dispatch_async(myViewController.backgroundQueue, ^(void) {
        [self.myViewController.myDictionaryManager downloadServeDictArrayAsynch];
    });

}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    [myViewController inputViewHack];
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
