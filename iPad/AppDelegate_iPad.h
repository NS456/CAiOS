//
//  AppDelegate_iPad.h
//  CAiOS
//
//  Created by Neville Smythe on 4/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MyViewController;
//@class MyDictionaryObject;

@interface AppDelegate_iPad : NSObject <UIApplicationDelegate> {
    UIWindow *window;    
    MyViewController *myViewController;
   // MyDictionaryObject *myDictionaryObject;
        
}

    
@property (nonatomic,strong) IBOutlet UIWindow *window;
@property (nonatomic,strong) MyViewController *myViewController;
//@property (nonatomic) MyDictionaryObject *myDictionaryObject;
    
@end
    
