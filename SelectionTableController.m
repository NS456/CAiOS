//
//  SelectionTableController.m
//  CAiOS
//
//  Created by Neville Smythe on 11/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SelectionTableController.h"
#import "MyViewController.h"
#import "DictionaryManager.h"

@interface SelectionTableController ()

@end

@implementation SelectionTableController {
    MyViewController * viewController;
    DictionaryManager * myDictionaryManager;
    
    UIBarItem * installButtonItem;
    int selectedRow, selectedSection;
    int currentDictionaryRow; //must be section 0!
    
    //int serverStatus; //0 not queried, 1 OK, 2 an error
   // NSArray* serverDictionaryArray;
    
    
}

@synthesize theTable;
@synthesize theToolbar, navBar;
@synthesize kind;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) assignMyViewController: (id)controller kind:(NSInteger)k {
    int i;
    UIBarItem* theItem;
    for (i=0; i<[[theToolbar items] count]; i++) {
        theItem = [[theToolbar items] objectAtIndex:i];
        if (theItem.tag == 2) {
            installButtonItem = theItem;
        }
    }
    
    viewController = controller;
    myDictionaryManager = viewController.myDictionaryManager;
    currentDictionaryRow = -1;
    selectedRow = -1; selectedSection = -1;
    //serverStatus = 0;
    self.kind = (int)k;
    switch (k) {
        case 0:
            [installButtonItem setTitle:@"Add/Remove"];
            [installButtonItem setEnabled:NO];
            break;
        case 1:
            [installButtonItem setTitle:@"Download & install"];
            [installButtonItem setEnabled:NO];
            
            //[self loadServerDictionaries]; serverDictionaryArray is loaded in b/g
            break;
           
        default:
            break;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    // Release any retained subviews of the main view.
    [super didReceiveMemoryWarning];
    self.theTable = nil;
    self.theToolbar = nil;
    self.navBar = nil;
}

/*
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    //return (UIInterfaceOrientationMaskAll);
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown);
}*/

- (BOOL)shouldAutorotate
{
    
    return YES;
}



#pragma mark -

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{	
    if ((kind == 0) && (indexPath.row == currentDictionaryRow)&&(indexPath.section == 0)) {
        cell.userInteractionEnabled = NO;
        cell.textLabel.enabled = NO; //could add a notation
    }
	
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (kind == 0) return 2;
    else return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection: (NSInteger) section {

    if (kind == 0) {
        if (section == 0) return @"Installed dictionaries";
        else return  @"Removed dictionaries";
    }
    else if ([myDictionaryManager.serverDictionaryArray count] == 0 ) return @"Server not available";
    else return @"Dictionaries on server";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (kind == 0) {
        if (section == 0) return [myDictionaryManager numberOfInstalledDictionaries];
        else return [myDictionaryManager numberOfRemovedDictionaries];
    }
    return [myDictionaryManager.serverDictionaryArray count];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedRow = (int)indexPath.row;
    selectedSection = (int)indexPath.section;
    
    switch (kind) {
        case 0:
            if (indexPath.section == 0) [installButtonItem setTitle:@"Remove"];
            else [installButtonItem setTitle:@"Install"];
            [installButtonItem setEnabled:YES];
            break;
        case 1:
            [installButtonItem setEnabled:YES];
            break;
            
        default:
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	int i;
    int n = (int)[myDictionaryManager.theDictionaries count];
    NSDictionary * sDict;
    
    MyDictionaryObject * theDict = nil;
    UITableViewCell * cell;
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    switch (kind) {
        case 0:
            if (indexPath.section == 0) {
                for (i=0;i<n;i++) {
                    theDict = [myDictionaryManager.theDictionaries objectAtIndex:i];
                    if (theDict.installedRowNumber == indexPath.row) break;
                }
            }
            else  {               
                for (i=0;i<n;i++) {
                    theDict = [myDictionaryManager.theDictionaries objectAtIndex:i];
                    if (theDict.removedRowNumber == indexPath.row) break;
                }
            }
            
            if (theDict == nil) {
                cell.textLabel.text = @"Error, dictionary not found";
            }
            else {
                cell.textLabel.text = [theDict dictName]; 
                if ([cell.textLabel.text isEqualToString:viewController.currentDictionary.dictName]) 
                    currentDictionaryRow = (int)indexPath.row;
            }
            break;
            
        case 1:
            sDict = [myDictionaryManager.serverDictionaryArray objectAtIndex:indexPath.row];
            cell.textLabel.text = [sDict objectForKey:@"name"];
            switch ([[sDict objectForKey:@"status"] integerValue]) {
                case 0:
                    cell.textLabel.textColor = [UIColor redColor];
                    break;
                case 1:
                    cell.textLabel.textColor = [UIColor blueColor];
                    break;
                case 2:
                    cell.textLabel.textColor = [UIColor blackColor];
                    break;
                  
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    //cell.textLabel.text = [NSString stringWithFormat:@"indpath %d %d",indexPath.row, indexPath.section];
    
    
    return cell;
}

#pragma mark -
#pragma mark actions

- (void) cancelButton:(id)sender {
    [viewController dismissSelectionTable];
}

- (void) installButton:(id)sender {
    NSMutableDictionary* sDict;
    
   //prevent any further processing!!
    [installButtonItem setTitle:@"Processing ..."];
    [installButtonItem setEnabled:NO];
    
    MyDictionaryObject* selDictionary = nil;
    int i=0;
    
    if (self.kind == 1) { //download and install a dictionary from the server
        sDict = [myDictionaryManager.serverDictionaryArray objectAtIndex:selectedRow];
        NSString* dName = [sDict objectForKey:@"name"];
        
        //NSLog(@"dName from selection *%@*",dName);
        
        [myDictionaryManager downLoadAndInstall:dName];
        
        
        //and update the item in the serverDictionaryArray! //assumes successfull download!
        //while waiting for the true update
        [sDict setObject:[NSNumber numberWithInteger:2] forKey:@"status"];
        viewController.dictionaryUpdateAvailable = NO;
        viewController.dictionaryAlertButton.hidden = YES;
        
        myDictionaryManager.needsArchiving = YES;

    }
    
    
    else { //remove or re-install a dictionary
        
        int n = (int)[myDictionaryManager.theDictionaries count];
        BOOL err;
        
        if  (selectedSection == 0) {        
            for (i=0; i<n; i++) {
                selDictionary = [myDictionaryManager.theDictionaries objectAtIndex:i];
                if (selDictionary.installedRowNumber == selectedRow) break;            
            }
        }
        else if (selectedSection == 1) {
            for (i=0; i<n; i++) {
                selDictionary = [myDictionaryManager.theDictionaries objectAtIndex:i];
                if (selDictionary.removedRowNumber == selectedRow) break;           
            }
        }
        
        if (i==n) {
            [viewController dismissSelectionTable];
        }
        
        if (selectedSection == 0) {
            //remove the selected dictionary from the Library
            [myDictionaryManager removeDictionaryFromLibrary:selDictionary];
        }
        else {
            //install the selected dictionary, from bundle or userDocs
            if (selDictionary.userSupplied) {
                //must check if the source still exists, otherwise put up a dlog
                if (!selDictionary.sourcePath) {
                    [viewController oopsAlert:@"Error" message:@"source path null - should not happen"];
                    return;
                }
                else if (![[NSFileManager defaultManager] fileExistsAtPath:selDictionary.sourcePath]) {
                    [viewController oopsAlert:@"Error" message:@"The dictionary source has been removed from the Documents folder, cannot re-install!"];
                    return;

                }
                
               err = [myDictionaryManager moveUserDictionaryToLibrary:[selDictionary.sourcePath lastPathComponent]];
            }
            else
                err = [myDictionaryManager moveBundledDictionaryToLibrary:selDictionary.sourcePath];
            
            if  (!err) [viewController setDictionary:selDictionary.dictName]; //not if error!!!!
            myDictionaryManager.needsArchiving = YES;
            
            
           [myDictionaryManager removeChanges:selDictionary.dictName];

            
         }

    }
        
    //finally
    [viewController dismissSelectionTable];
    
    //if dictionaries list changed
    if (viewController.gShowingDictionaryList) {
        [viewController showDictionaryList];        
        [viewController.dictPicker reloadAllComponents];
    }
    
}


@end
