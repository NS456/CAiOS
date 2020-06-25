//
//  MyViewController.h
//  CAiOS
//
//  Created by Neville Smythe on 7/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#define MAXPATLENGTH 35
//20 v1.1 value
#define MAXANAGLENGTH MAXPATLENGTH
//30
#define MAXNUMWORDS 10
//1
#define MAXWORDLENGTH 36
//21 //must be MAXPATLENGTH+MAXNUMWORDS; store words length 1 to (MAXWORDLENGTH-1)
// decide -store phrases in a different sequence of files, phrases3.txt to phrases46.txt
#define MAXPHRASELENGTH 46 
//for phrases 3 to 46 chars inc spaces

#import <UIKit/UIKit.h>
#import "DictionaryManager.h"
#import "InfoViewController.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>

//#import "KeyboardAccessoryView.h"

@class SelectionTableController;

@interface MyViewController : UIViewController <UIPickerViewDelegate,UIPickerViewDataSource, UIActionSheetDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate> {
	UITextField *numLettersField;
	UITextField *anagramField;
	UITextField *patternField;
	UITextView *resultsField;
	UIButton *currentDictionaryButton;
	UILabel *numResultsLabel;
	UIButton *lengthLock;
	UIButton *plusButton;
	UIButton *addDeleteButton;
    UIButton *lookupButton;
    UIButton *infoButton;
    UIButton *dictionaryAlertButton;
    
    UIView * backView;
    
//    UILabel *doneTip;
	
    DictionaryManager*   myDictionaryManager;
    SelectionTableController * mySelectionTableController;
	
	MyDictionaryObject * currentDictionary;
	NSString *currNumLettersFieldText,*currPatternFieldText,*currAnagramFieldText;
	BOOL lengthlockFlag;
    BOOL newVersion; //used by a version update to reinstall dictionaries
    BOOL prefsNeedSaving;
    BOOL dictionaryUpdateAvailable;
    
    
    UIPickerView * dictPicker;
	
    InfoViewController * infoViewController;
    
    NSString* uniqueAppID;
    dispatch_queue_t backgroundQueue;

}

- (void) dismissInfoView;


@property (nonatomic,strong) IBOutlet UITextField *numLettersField;
@property (nonatomic,strong) IBOutlet UITextField *patternField;
@property (nonatomic,strong) IBOutlet UITextField *anagramField;
@property (nonatomic,strong) IBOutlet UITextView *resultsField;
@property (nonatomic,strong) IBOutlet UIButton *currentDictionaryButton;
@property (nonatomic,strong) IBOutlet UILabel *numResultsLabel;
@property (nonatomic,strong) IBOutlet UIButton *lengthLock;
@property (nonatomic,strong) IBOutlet UIButton *plusButton;
@property (nonatomic,strong) IBOutlet UIButton *addDeleteButton;
@property (nonatomic,strong) IBOutlet UIButton *lookupButton;
@property (nonatomic,strong) IBOutlet UIButton *infoButton;
@property (nonatomic,strong) IBOutlet UIButton *dictionaryAlertButton;

@property (nonatomic,strong) IBOutlet UIView *backView;

//@property (nonatomic,strong) IBOutlet UILabel *doneTip;

@property (nonatomic,strong) DictionaryManager * myDictionaryManager;
@property (nonatomic,strong) SelectionTableController * mySelectionTableController;

@property (nonatomic,strong) MyDictionaryObject *currentDictionary;
@property (nonatomic,strong) NSString *currNumLettersFieldText;
@property (nonatomic,strong) NSString *currPatternFieldText;
@property (nonatomic,strong) NSString *currAnagramFieldText;

@property BOOL lengthlockFlag, newVersion, prefsNeedSaving;
@property BOOL gShowingDictionaryList, dictionaryUpdateAvailable;

@property (nonatomic,strong) UIInputView * numberpad;
@property (nonatomic,strong) UIInputView * alphapad;
@property (nonatomic,strong) IBOutlet UIPickerView * dictPicker;

@property (nonatomic,strong) InfoViewController * infoViewController;

@property (nonatomic,strong) NSString* uniqueAppID;

@property dispatch_queue_t backgroundQueue;

- (void) setDictionary:(NSString*)dName;
//- (void) keyboardWillAppear;
//- (void) keyboardDidDismiss;

+ (int) hasConnectivity;

- (void) serverDictionariesUpdated:(id)sender;

- (void) inputViewHack;

/* add IBactions here*/

- (IBAction)lengthLockTouchDown:(id)sender;
- (IBAction)plusButtonTouchDown:(id)sender;
- (IBAction)addDeleteButtonTouchDown:(id)sender;
- (IBAction)lookupTouchDown:(id)sender;
- (void) doLookup;
- (void) putLang:(NSNumber*)num;
- (void) putEngType:(NSNumber*)num;
- (void) putURLType:(NSNumber*)num;
- (void) putUserURL:(NSString*)urlString;

- (IBAction)numberpadButton:(id)sender;
- (IBAction)alphapadButton:(id)sender;

- (IBAction) chooseDictionary:(id)sender;
- (IBAction) infoButton:(id)sender;

- (IBAction)textFieldChanged:(id)sender;
- (IBAction)textFieldEditingBegin:(id)sender;
- (void) textViewDidChangeSelection:(id) sender;

- (void) alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger) i;

- (void) dismissSelectionTable;

- (void) oopsAlert:(NSString*)aTitle message:(NSString*)aMessage;

- (void) showDictionaryList;

@end
