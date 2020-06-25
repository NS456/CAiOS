//
//  SelectionTableController.h
//  CAiOS
//
//  Created by Neville Smythe on 11/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate_iPhone.h" //actual call will be the device specific code presumably


@interface SelectionTableController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    UITableView* theTable;
    int kind;
    UIToolbar* theToolbar;
    UINavigationBar * navBar ;
}

- (void) assignMyViewController: (id)controller kind:(NSInteger)k;

- (IBAction) cancelButton:(id)sender;
- (IBAction) installButton:(id)sender;

@property (nonatomic,strong) IBOutlet UITableView* theTable;
@property (nonatomic,strong) IBOutlet UIToolbar* theToolbar;
@property (nonatomic,strong) IBOutlet UINavigationBar * navBar;
@property int kind;

@end
