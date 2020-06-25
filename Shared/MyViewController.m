//
//  MyViewController.m
//  CAiOS
//
//  Created by Neville Smythe on 7/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyViewController.h"
#import "MyDictionaryObject.h"
#import "AppDelegate_iPhone.h" //actual call will be the device specific code presumably
#import "SelectionTableController.h"
//#import "KeyboardAccessoryView.h"

@interface MyViewController (PrivateUtilities)

- (NSString*) modifyText:(NSString*)myText;
- (BOOL) OKtoSearch;
- (void) checkVersion;
- (void) addGestureRecognizersToView:(UIView *)theView;
- (void) tapPiece:(UITapGestureRecognizer *)gestureRecognizer;
- (void) setMyPrefsKey:(CFStringRef)prefKey toVal:(CFStringRef) prefVal;

@end


@implementation MyViewController

char thePattern[MAXPATLENGTH];
char theAnagram[MAXANAGLENGTH];

NSString* gSelString; //global to hold string to lookup meaning
langTypeNum  gLang;
engTypeNum gEnglishType;
urlTypeNum gURL;

NSString* dictStr = @"https://www.collinsdictionary.com/dictionary/$/*?q=*";
NSString* wikiStr = @"https://!.m.wiktionary.org/wiki/*"; //was wikipedia
NSString* googleStr = @"https://google.com/search?q=*#q=*&hl=!";
NSString* onelookStr = @"http://www.onelook.com/?w=*";

NSString* defUserStr = @"https://!.wikipedia.org/wiki/*";
NSString* altdUserString = @"http://www.merriam-webster.com/dictionary/*";
NSString* altbUserString = @"https://www.britannica.com/search?query=*";
NSString* userURLStr;

UIActionSheet* menuSheet;
UIAlertController* menuController;
UIPresentationController* alertSheetPresentationController;
BOOL menuSheetActive = NO;

BOOL resetPatternSelection;
BOOL isTrimmed;

@synthesize myDictionaryManager, mySelectionTableController;
@synthesize numLettersField;
@synthesize anagramField;
@synthesize patternField;
@synthesize resultsField;
@synthesize currentDictionaryButton;
@synthesize currentDictionary;
@synthesize currNumLettersFieldText;
@synthesize currPatternFieldText;
@synthesize currAnagramFieldText;
@synthesize addDeleteButton;
@synthesize lookupButton;
@synthesize lengthLock;
@synthesize plusButton, infoButton, dictionaryAlertButton;
@synthesize numResultsLabel;
@synthesize lengthlockFlag, newVersion, prefsNeedSaving;
@synthesize dictPicker;
@synthesize backView;
@synthesize gShowingDictionaryList, dictionaryUpdateAvailable;

@synthesize numberpad, alphapad;

@synthesize infoViewController;
@synthesize uniqueAppID;
@synthesize backgroundQueue;

- (void) finishLoading:(id)sender {
    
    myDictionaryManager = [[DictionaryManager alloc] initWithViewController:self];
    //this initialisation needs appdelegate.viewcontroller to be set?? So delay the rest
    
    //read preferences
    CFStringRef prefVal;
    BOOL bval;
    NSString* defDictionary;
    
    resetPatternSelection = NO;    
    prefsNeedSaving = NO;
    
    CFStringRef prefKey = CFSTR("lengthLockFlag");
    prefVal = (CFStringRef)CFPreferencesCopyAppValue(prefKey,
                                                     kCFPreferencesCurrentApplication);
    if (prefVal == nil) {
        self.lengthlockFlag = YES;
        [self.lengthLock setSelected:YES];
    }
    else  {
        bval = (CFStringCompare(prefVal, CFSTR("Locked"),kCFCompareCaseInsensitive) == 0);
        self.lengthlockFlag = bval;
        [self.lengthLock setSelected:bval];
        CFRelease(prefVal);
    }
    
    prefKey = CFSTR("dictionary");
    prefVal = (CFStringRef)CFPreferencesCopyAppValue(prefKey,
                                                     kCFPreferencesCurrentApplication);
    if (prefVal == nil) {
        defDictionary = @"English";
    }
    else  {
        defDictionary = (__bridge NSString*)prefVal;
        CFRelease(prefVal);
    }
    
    prefKey = CFSTR("languagePref");
    prefVal = (CFStringRef)CFPreferencesCopyAppValue(prefKey,
                                                     kCFPreferencesCurrentApplication);
    if (prefVal == nil) {
        gLang = kEnglish;
    }
    else  {
        gLang = [(__bridge NSString*)prefVal intValue];
        CFRelease(prefVal);
    }
    
    prefKey = CFSTR("engTypePref");
    prefVal = (CFStringRef)CFPreferencesCopyAppValue(prefKey,
                                                     kCFPreferencesCurrentApplication);
    if (prefVal == nil) {
        gEnglishType = kBritishEnglish;
    }
    else  {
        gEnglishType = [(__bridge NSString*)prefVal intValue];
        CFRelease(prefVal);
    }

    
    prefKey = CFSTR("urlTypePref");
    prefVal = (CFStringRef)CFPreferencesCopyAppValue(prefKey,
                                                     kCFPreferencesCurrentApplication);
    if (prefVal == nil) {
        gURL = kDictionary;
    }
    else  {
        gURL = [(__bridge NSString*)prefVal intValue];
        CFRelease(prefVal);
    }

    prefKey = CFSTR("userURLPref");
    prefVal = (CFStringRef)CFPreferencesCopyAppValue(prefKey,
                                                     kCFPreferencesCurrentApplication);
    if (prefVal == nil) {
        userURLStr = defUserStr;
    }
    else  {
        userURLStr = (__bridge NSString*)prefVal;
        CFRelease(prefVal);
    }

    
	//[currentDictionaryButton setTitle:currentDictionary.dictName forState:UIControlStateNormal];
    [self setDictionary:defDictionary];
    
    //get saved settings and restore
    prefKey = CFSTR("lastNumLettersPref");
    prefVal = (CFStringRef)CFPreferencesCopyAppValue(prefKey,
                                                     kCFPreferencesCurrentApplication);
    if (prefVal == nil) {
        [self.numLettersField setText:@""];
    }
    else  {
        [self.numLettersField setText:(__bridge NSString*)prefVal];
        CFRelease(prefVal);
    }
    prefKey = CFSTR("lastPatternPref");
    prefVal = (CFStringRef)CFPreferencesCopyAppValue(prefKey,
                                                     kCFPreferencesCurrentApplication);
    if (prefVal == nil) {
        [self.patternField setText:@""];
    }
    else  {
        [self.patternField setText:(__bridge NSString*)prefVal];
        CFRelease(prefVal);
    }
    prefKey = CFSTR("lastAnagramPref");
    prefVal = (CFStringRef)CFPreferencesCopyAppValue(prefKey,
                                                     kCFPreferencesCurrentApplication);
    if (prefVal == nil) {
        [self.anagramField setText:@""];
    }
    else  {
        [self.anagramField setText:(__bridge NSString*)prefVal];
        CFRelease(prefVal);
    }

    [self textFieldChanged:anagramField];
    [self textFieldChanged:patternField];
    [self textFieldChanged:numLettersField];

    
    self.uniqueAppID = [self myUniqueID];
    
    //show/hide notification for updates to dictionaries - should be in b/g
    dictionaryUpdateAvailable = NO;
    [dictionaryAlertButton setHidden:YES];
    backgroundQueue = dispatch_queue_create("com.NSSoftware.bgqueue", NULL);
    
    dispatch_async(backgroundQueue, ^(void) {
        [self.myDictionaryManager downloadServeDictArrayAsynch];
        });
    
}

- (void) inputViewHack {
//on first display of keyboard inout View in iOS9 an extra inputaccessory view is shown
//this hack seems to fix // probably du to windows being created before app finished loading (got this error from simulator -- should move from appDelegate to viewdidload
[self.numberpad.window setHidden:YES];
[self.numLettersField becomeFirstResponder];
[self.numLettersField resignFirstResponder];
[self.numberpad.window setHidden:NO];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    	
	// to fix the controller showing under the status bar //for iPhone we suppress the status bar???
	self.view.frame = [[UIScreen mainScreen] applicationFrame];
    
    //self.automaticallyAdjustsScrollViewInsets = NO; //may need this to fix posn for iOS7 - doesnt seem to help
    
    self.infoViewController = nil;
    
    //hide the AddDeleteButton
	addDeleteButton.hidden = YES;
    [self showDefinition:NO];
	
    NSString * aString = @"";
	self.currNumLettersFieldText = aString;
	self.currPatternFieldText = aString;
	self.currAnagramFieldText = aString;
    
    self.numLettersField.delegate = self;
    self.patternField.delegate = self;
    self.anagramField.delegate = self;
    
    
    
    isTrimmed = NO;
    
	//set text & font for resultField
	[resultsField setFont:[UIFont fontWithName:@"CourierNewPS-BoldMT" size:18.0]];
    [self addGestureRecognizersToView:resultsField];
    
    [self checkVersion]; //read the app version, check against stored value in prefs, store it, remove archive if new
    
    // register for server dictionary updates
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDictionariesUpdated:) name:@"com.NSSoftware.serverArrayUpdated" object:nil];
        
    //initialising the dictionaryManager needs appdelegate to have finished loading	
    //hmm there may be a circular loading requirement here! 
    //[self performSelector:@selector(finishLoading:) withObject:self afterDelay:0.00];
    [self finishLoading:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    //return (UIInterfaceOrientationMaskAll);
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown);
}

- (BOOL)shouldAutorotate
{
    
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"com.NSSoftware.serverArrayUpdated" object:nil];
}


- (void) serverDictionariesUpdated:(id)sender {
    //update relevant table items for update in server list, if still in table
    if ((mySelectionTableController)&&(mySelectionTableController.view.superview == self.view)) {
        [mySelectionTableController.theTable reloadData];
    }
}

- (void) showDefinition: (BOOL) show {
    if (show) {
        lookupButton.hidden = NO;
        [numResultsLabel setHidden:YES];
    }
    else {
        lookupButton.hidden = YES;
        [numResultsLabel setHidden:NO];
    }
}


//- (void)viewWillAppear:(BOOL)animated {
//}

- (BOOL) textFieldShouldClear:(UITextField *)textField {
    if (textField == numLettersField) {
        [numLettersField setText:@""]; //this should set numWords etc - does it???
        [patternField setText:@""];
        [resultsField setText:@""];
        [numResultsLabel setText:@""];
        [self showDefinition:NO];
        [numLettersField becomeFirstResponder];
        return NO;
    }
    if (textField != patternField) return YES;
    if (!lengthlockFlag) {
        [numLettersField setText:@""]; //this should set numWords etc - does it???
        //[anagramField setText:@""];
        [resultsField setText:@""];
        [numResultsLabel setText:@""];
        [self showDefinition:NO];
       return YES; 
    }
    [patternField setText:[self modifyText:@""]]; //to reset def pattern and set currentPattern etc
    //resetPatternSelection = YES;
    [patternField becomeFirstResponder];
    UITextRange * sel = [patternField textRangeFromPosition:[patternField beginningOfDocument] toPosition:[patternField beginningOfDocument]];
    [patternField setSelectedTextRange:sel];
    
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if ((textField==patternField)&&(lengthlockFlag)&&(currentDictionary.theFullLength == 0)) {
        [resultsField setTextColor:[UIColor redColor]];
        [resultsField setText:@"Locked mode: the pattern length is set by the number of letters field. Please set number of letters first, or unlock"];
        return;
    }

    if ((resetPatternSelection)&&(textField == patternField)) {
        UITextRange * sel = [patternField textRangeFromPosition:[patternField beginningOfDocument] toPosition:[patternField beginningOfDocument]];
        [ patternField setSelectedTextRange:sel]; // cannot do this while editing numLetters evidently
    }
    
}

- (NSString*) modifyText:(NSString*)myText {
 	char oldString[MAXPATLENGTH], newString[MAXPATLENGTH];
	int i,j,k,L;
    
	L = (int)[myText length];
    
	for (i=0;i<currentDictionary.theFullLength;i++) {
		if (i<L) {oldString[i]=[myText characterAtIndex:i];}
		else oldString[i]='-';
        newString[i]='-'; 
	}
        
	j=0; k=0; L=-1;
	for (i=0;i<currentDictionary.theFullLength;i++) {
		if ((k<currentDictionary.theNumWords) && (j == 1+L+[currentDictionary theWordLengths:k])) {
			newString[j] = ',';
			k++; L=j; j++;
            //we should insert comma, not replace char with comma
            if (oldString[i] != ',') {
                newString[j]=oldString[i]; j++;
            }
		}
		else if (oldString[i] == ',') {} //skip old commas
		else { newString[j]=oldString[i]; j++;}
	}
    
	newString[currentDictionary.theFullLength] = 0;
    
    //set pattern to the conforming pattern 
    [currentDictionary setPattern:[NSString stringWithCString:(char*)&newString encoding: NSMacOSRomanStringEncoding]];    
    
    self.currPatternFieldText = [NSString stringWithCString:(char*)&newString encoding: NSMacOSRomanStringEncoding];
    
    return self.currPatternFieldText;
   
}

//interface control

//delegations and notifications

- (void) playClickForCustomKeyTap {    
    [[UIDevice currentDevice] playInputClick];
}

- (IBAction)numberpadButton:(id)sender {
    int which = (int)[(UIButton*)sender tag];
    //NSString * str;
    UITextRange * sel = numLettersField.selectedTextRange;
    
    UITextPosition * selStart = sel.start;
    UITextPosition * selEnd = sel.end;
    UITextPosition * newStart, * newEnd;
    
    [self playClickForCustomKeyTap];
    
    if (which <= 10) {
        [numLettersField replaceRange:sel withText:[NSString stringWithFormat:@"%c",[@"0123456789," characterAtIndex:which]]];
    }

    else switch (which) {
        case 11:
        case 13:
            if ([numLettersField comparePosition:selStart toPosition:selEnd]!=0) {
                if (which == 11) [numLettersField replaceRange:sel withText:@""];
                else [numLettersField setSelectedTextRange:[numLettersField textRangeFromPosition:selStart toPosition:selStart]];
            }
            else {
                newStart = [numLettersField positionFromPosition:selStart offset:-1];
                if (newStart != nil) {
                    if (which == 11) [numLettersField replaceRange:[numLettersField textRangeFromPosition:newStart toPosition:selEnd] withText:@""];
                    else {
                        [numLettersField setSelectedTextRange:[numLettersField textRangeFromPosition:newStart toPosition:newStart]];
                    }
                }
            }
            break;
        case 12:
        case 14:
            if ([numLettersField comparePosition:selStart toPosition:selEnd]!=0) {
                if (which == 12) [numLettersField replaceRange:sel withText:@""];
                else [numLettersField setSelectedTextRange:[numLettersField textRangeFromPosition:selEnd toPosition:selEnd]];
            }
            else {
                newEnd = [numLettersField positionFromPosition:selEnd offset:1];
                if (newEnd != nil) {
                    if (which == 12) [numLettersField replaceRange:[numLettersField textRangeFromPosition:selStart toPosition:newEnd] withText:@""];
                    else {
                        [numLettersField setSelectedTextRange:[numLettersField textRangeFromPosition:newEnd toPosition:newEnd]];
                    }
                }
            }
            break;
        
        case 15: //Done
            //str = numLettersField.text; //this must be normalised
            //make sure all fields are processed because can change editted field without hitting Done
            //[self textFieldChanged:numLettersField];
            //[self textFieldChanged:anagramField];
            //[self textFieldChanged:patternField];
            [numLettersField resignFirstResponder];
            if ([self OKtoSearch]) [self doSearch];
            break;
            
        default:
            break;
    }
}

- (void) trimTextForField:(UITextField*)theTextField {
    //using settext rather than replace range seems to invalidate the textRanges
    
    NSString* newStr, *theText = [theTextField text];
    int L,M = (int)[theText length];
   
    if (theTextField == patternField) {
        if (lengthlockFlag) L = currentDictionary.theFullLength; //presume theFullLength is tested...
        else L = MAXPATLENGTH;
        if (M > L) theText = [theText substringToIndex:L];
        
        newStr = [self modifyText:theText];
    }
    else  {
        newStr = theText;
        if (M > MAXANAGLENGTH) newStr = [theText substringToIndex:MAXANAGLENGTH];
    }
    
    UITextRange* maxRange = [theTextField textRangeFromPosition:[theTextField beginningOfDocument]
                                                         toPosition:[theTextField endOfDocument]];
    [theTextField replaceRange:maxRange withText:newStr];
    
    isTrimmed = YES;
    
}

- (IBAction)alphapadButton:(id)sender {
    int which = (int)[(UIButton*)sender tag];
    int i;
    UITextField * theTextField;
    
    
    if ([patternField isFirstResponder]) {
        theTextField = patternField;
        
    }
    else if ([anagramField isFirstResponder]) {
        theTextField = anagramField;
    }
    else {
        theTextField = nil;        
        return;
    }
    
    UITextRange * sel = theTextField.selectedTextRange;
    UITextPosition * selStart = sel.start;
    UITextPosition * selEnd = sel.end;
    UITextPosition * newStart, * newEnd;
    NSString* theText = [theTextField text];
    NSInteger s0 = [theTextField offsetFromPosition:[theTextField beginningOfDocument] toPosition:sel.start];

    if (theTextField == patternField) {
        if ((s0 >= MAXPATLENGTH)||((lengthlockFlag)&&(s0 > currentDictionary.theFullLength))) return;
    }
    if ((theTextField == anagramField) && (s0 >= MAXANAGLENGTH)) return;
    
    [self playClickForCustomKeyTap];
    
    if (which == 26) { //comma
        //inhibit comma in 1. anagramField 2.locked pattern if not wordbreak 0. always at start, or doubled
        if (s0 == 0) ; //do nothing! even for a selection

        else if (theTextField == anagramField) ; //don't allow comma in anagram field

        else if ([theText characterAtIndex:s0-1] == ',') ; //do nothing if preceding character is comma
                
        else if ((s0 < [theText length]-1) && ([theText characterAtIndex:s0+1] == ',')) ; //don't allow if next char is comma

        else if (lengthlockFlag) { //for locked patternField, only allow at word breaks
            int L = -1;
            for (i=0;i<currentDictionary.theNumWords;i++) {
                L = L + [currentDictionary theWordLengths:i];
                if (s0 == 1+L) {
                    [theTextField replaceRange:sel withText:@","];
                    [self trimTextForField:theTextField];
                    if (s0<[[theTextField text] length]) s0++; else s0 = [[theTextField text] length];
                    newStart = [theTextField positionFromPosition:[theTextField beginningOfDocument] offset:s0];
                    [theTextField setSelectedTextRange:[theTextField textRangeFromPosition:newStart toPosition:newStart]];
                    break;
                }
            }
        }
            
        else {
            [theTextField replaceRange:sel withText:@","];
            [self trimTextForField:theTextField];
            if (s0<[[theTextField text] length]) s0++; else s0 = [[theTextField text] length];
            newStart = [theTextField positionFromPosition:[theTextField beginningOfDocument] offset:s0];
            [theTextField setSelectedTextRange:[theTextField textRangeFromPosition:newStart toPosition:newStart]];
        }
    }
    
    else if (which <= 29) {
        [theTextField replaceRange:sel withText:[NSString stringWithFormat:@"%c",[@"ABCDEFGHIJKLMNOPQRSTUVWXYZ,-@$" characterAtIndex:which]]];
        [self trimTextForField:theTextField];
        if (s0<[[theTextField text] length]) s0++; else s0 = [[theTextField text] length];
        newStart = [theTextField positionFromPosition:[theTextField beginningOfDocument] offset:s0];
        [theTextField setSelectedTextRange:[theTextField textRangeFromPosition:newStart toPosition:newStart]];
    }
    
    else switch (which) {
        case 111:
        case 113:
            if ([theTextField comparePosition:selStart toPosition:selEnd]!=0) {
                if ((which == 111)&&([theText characterAtIndex:s0-1] != ',')) {
                    [theTextField replaceRange:sel withText:@""];
                    [self trimTextForField:theTextField];
                    newStart = [theTextField positionFromPosition:[theTextField beginningOfDocument] offset:s0-1];
                    [theTextField setSelectedTextRange:[theTextField textRangeFromPosition:newStart toPosition:newStart]];
                }
                else {
                   [theTextField setSelectedTextRange:[theTextField textRangeFromPosition:selStart toPosition:selStart]];
                }
            }
            else {
                newStart = [theTextField positionFromPosition:selStart offset:-1];
                if (newStart != nil) {
                    if ((which == 111)&&([theText characterAtIndex:s0-1] != ',')) {
                        [theTextField replaceRange:[theTextField textRangeFromPosition:newStart toPosition:selEnd] withText:@""];
                        [self trimTextForField:theTextField];
                        newStart = [theTextField positionFromPosition:[theTextField beginningOfDocument] offset:s0-1];
                        [theTextField setSelectedTextRange:[theTextField textRangeFromPosition:newStart toPosition:newStart]];
                    }
                    else {
                        [theTextField setSelectedTextRange:[theTextField textRangeFromPosition:newStart toPosition:newStart]];
                    }
                }
            }
            break;
        case 112:
        case 114:
            if ([theTextField comparePosition:selStart toPosition:selEnd]!=0) {
                if ((which == 112)&&([theText characterAtIndex:s0] != ',')) {
                    [theTextField replaceRange:sel withText:@""];
                    [self trimTextForField:theTextField];
                    newStart = [theTextField positionFromPosition:[theTextField beginningOfDocument] offset:s0+1];
                    //check thios does not crash!!! prob will must adjust s0 - also at 0 ??
                    [theTextField setSelectedTextRange:[theTextField textRangeFromPosition:newStart toPosition:newStart]];
                }
                else [theTextField setSelectedTextRange:[theTextField textRangeFromPosition:selEnd toPosition:selEnd]];
            }
            else {
                newEnd = [theTextField positionFromPosition:selEnd offset:1];
                if (newEnd != nil) {
                    if ((which == 112)&&([theText characterAtIndex:s0] != ',')) {
                        [theTextField replaceRange:[theTextField textRangeFromPosition:selStart toPosition:newEnd] withText:@""];
                        [self trimTextForField:theTextField];
                        newStart = [theTextField positionFromPosition:[theTextField beginningOfDocument] offset:s0+1];
                        [theTextField setSelectedTextRange:[theTextField textRangeFromPosition:newStart toPosition:newStart]];
                    }
                    else {
                        [theTextField setSelectedTextRange:[theTextField textRangeFromPosition:newEnd toPosition:newEnd]];
                    }
                }
            }
            break;
            
        case 115: //Done
            //str = theTextField.text; //this must be normalised
            //[self textFieldChanged:theTextField];
            //make sure all fields are processed because can change editted field without hitting Done
            //[self textFieldChanged:numLettersField];
            //[self textFieldChanged:anagramField];
            //[self textFieldChanged:patternField];
            [theTextField resignFirstResponder];
            //if ([self OKtoSearch]) [self doSearch];
            break;
            
        default:
            break;
    }    
}

- (BOOL) isSelectionLegal {
    int i,j,k;
    char c;
    
    NSMutableString* selString = [NSMutableString stringWithString:[currentDictionary.searchResults substringWithRange:[resultsField selectedRange]]];
    
    NSString* dString = [selString stringByReplacingOccurrencesOfString:@"\n" withString:@"  "];
    
    //strip spaces from front and back
    j = 0; k = (int)[dString length];
    for (i=0; i<k; i++) {
        c = [dString characterAtIndex:i];
        if (c == ' ') j++;
        else break;
    }
    if (j == k-1) {
        gSelString = nil;
        return NO;
    }

    for (i=k-1; i>j; i--) {
        c = [dString characterAtIndex:i];
        if (c == ' ') k--;
        else break;
    }
        
    NSString* eString = [dString substringWithRange:NSMakeRange(j, k-j)];
    NSRange rr = [eString rangeOfString:@"  "];
    
    if (rr.length != 0) {
        gSelString = nil;
        return NO;
    }
    
    gSelString = [eString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    gSelString = [gSelString lowercaseString];
    //may not be ncessary, and some sites prefer to + or use _ ????
    //gSelString = eString;
    return YES;
}

- (void) textViewDidChangeSelection:(id) sender{
    //check sender is resultField and that selection change has finished
    if (sender == resultsField) {
        if (resultsField.selectedRange.length == 0) {
            [addDeleteButton setHidden:YES];
            [self showDefinition:NO];
        }
        else if (CGColorEqualToColor(resultsField.textColor.CGColor, [UIColor blackColor].CGColor)) {
            [addDeleteButton setTitle:@"Delete" forState:UIControlStateNormal];
            [addDeleteButton setHidden:NO];
            
            if ([self isSelectionLegal]) {
               [self showDefinition:YES];
            }
            else {
                [self showDefinition:NO];
            }
        }
    }
}

- (void) hideDictionaryPicker {
    [currentDictionaryButton setHidden:NO]; //on an iPad it was hidden when dictPicker appears
    [dictPicker setHidden:YES];

}


- (IBAction)textFieldEditingBegin:(id)sender{    
    [self hideDictionaryPicker];
    return;
 }


//track changes in text controls length, pattern and anagram
- (IBAction)textFieldChanged:(id)sender
{	NSString * myText;
	int i,j,k, test, newNumWords,L,numSpaces=0;
	int newWordLengths[MAXNUMWORDS], wordBreaks[MAXPHRASELENGTH];
	char *cStr;
	char ch;
	//NSRange theSelPoint;
	BOOL expectDigit; 
	//NSMutableString *theLengthStr;
    static BOOL isProcessing = NO;
    //BOOL patternFieldChanged = YES;
    BOOL anagramFieldChanged = YES;
    
    
    if (isProcessing) return; //to prevent loop as one text field change triggers another
    isProcessing = YES;
    
    //UITextField* theTextField = (UITextField*)sender;
    
   // UITextRange * tsel = theTextField.selectedTextRange;
   // NSInteger s0 = [theTextField offsetFromPosition:[theTextField beginningOfDocument] toPosition:tsel.start];
	
	myText = [sender text];
	
    if (sender == numLettersField) { 
        
        //clean up the text string //preferably done i  keyboard input ???
        k = (int)[myText length];
        
        i = 0;
        while (i<k) {
            if (([myText characterAtIndex:0] == '0')||([myText characterAtIndex:0] == ',')) {
                myText = [myText substringFromIndex:1];
                k--;
            }
            else break;
        }
        i = 1;
        while (i<k) {
            if (([myText characterAtIndex:i] == '0')||([myText characterAtIndex:i] == ',')) {
                if ([myText characterAtIndex:i-1] == ',') {
                    myText = [[myText substringToIndex:i] stringByAppendingString:[myText substringFromIndex:i+1]];
                    k--;
                }
                else i++;
           }
            else i++;
        }
        
        [numLettersField setText:myText];
        		
		if ([myText length] == 0) {
			currentDictionary.numLetters = myText;
			currentDictionary.theLength = 0;
			currentDictionary.theFullLength = 0;
			currentDictionary.theNumWords = 0;
			//other settings, eg valid???
			[numLettersField setText:myText];
            if (lengthlockFlag) {
                [resultsField setTextColor:[UIColor redColor]];
                [resultsField setText:@"Please set number of letters"];
            }
            [numResultsLabel setText:@""];
            [self showDefinition:NO];
            gShowingDictionaryList = NO;
           isProcessing = NO;
            
			return;}
        				
        j=0; for (i=0;i<MAXNUMWORDS;i++) {newWordLengths[i]=0;} newNumWords=0;
        k = (int)[myText length];
        
        if (k>0)  { 
            cStr=(char *)[myText cStringUsingEncoding: NSMacOSRomanStringEncoding];
            expectDigit=YES; 
            
            for (i=0;i<=k;i++) { 
                ch=cStr[i];            
                if ((ch>='0')&&(ch<='9')) {
                    expectDigit=NO;
                    test=10*newWordLengths[newNumWords]+(ch-'0');
                    if (test<MAXWORDLENGTH) {newWordLengths[newNumWords]=test;}
                    else {myText=[myText substringToIndex:i]; j=0; break;} //j=0 don't process?? But should reprocess                   
				}
                else if ((!expectDigit && (ch==','))||(ch==0)) {
                    //if (i==k-1) {} {j=0; break;} //last entry is , - don't process
                    j = j+ newWordLengths[newNumWords];
                    newNumWords++; if (ch==',') numSpaces++;
                    if (newNumWords>MAXNUMWORDS) {j=MAXPATLENGTH+1;} //!!!Must be<MAXNUMWORDS
                    expectDigit=YES;
				}
                else { //ignore any other char
                    myText=[myText substringToIndex:i];
                    j=0;
                    break;}
			}
		}
		
        if (j>MAXPHRASELENGTH) {[numLettersField setText:[currentDictionary numLetters]];  return;} //too long
        else if (j<1) //do not process user input
		{   
            [numLettersField setText:myText]; //and reprocess
            //[self textFieldChanged:sender];
            isProcessing = NO;
            return;}
        else  {            
			self.currNumLettersFieldText = myText;
            [numLettersField setText:myText];
			currentDictionary.numLetters = myText;
            
			currentDictionary.theNumWords=newNumWords;
			
            for (i=0;i<MAXNUMWORDS;i++) [currentDictionary setTheWordLengths:i :newWordLengths[i]];
            			
			L = 0;
			for (k=0; k<newNumWords; k++) {
				L = L + newWordLengths[k];
			}
			currentDictionary.theLength = L;
			currentDictionary.theFullLength = L + newNumWords -1;
			
		}
        		
		//modify pattern to conform
        [patternField setText:[self modifyText:[patternField text]]];
        resetPatternSelection = YES;
        
        isProcessing = NO;
        
        if ([self OKtoSearch]) [self doSearch];
        
        CFStringRef prefKey = CFSTR("lastNumLettersPref");
        [self setMyPrefsKey:prefKey toVal:(__bridge CFStringRef)(numLettersField.text)];
        prefsNeedSaving = YES;
		 
	}

	else if (sender == patternField)  {
        if (lengthlockFlag) {
            if (!isTrimmed) { //to allow for paste; other changes are handles by alphapad
               //we could be pasting some illegal characters
                cStr=(char *)[myText cStringUsingEncoding: NSMacOSRomanStringEncoding];
                
                j=0;
                for (i=0;i<strlen(cStr);i++) {
                    ch=cStr[i];
                    if ((ch>=97) && (ch<=122)) {ch=ch-32;} //a-z
                    else if ((ch>=64) && (ch<=90)) {;}  //@A-Z
                    else if ((ch==45)||(ch==36)||ch==',') {;} //wildcards - and $ and ,
                    else { continue; //ignore anything else, inc space, comma
                    }
                    if (j<MAXPATLENGTH) {thePattern[j]=ch; j++;} else break;
                }
                thePattern[j]=0;
                [patternField setText:[NSString stringWithCString:thePattern encoding: NSMacOSRomanStringEncoding ]];
                

                [self trimTextForField:patternField];
            }
        }
        
        else  {
            
            for (i=0;i<MAXPHRASELENGTH;i++) {wordBreaks[i]=0;}
            cStr=(char *)[myText cStringUsingEncoding: NSMacOSRomanStringEncoding];
			
			j=0;
            int numWordBreaks = 0;
			for (i=0;i<strlen(cStr);i++) {
				ch=cStr[i];
				if ((ch>=97) && (ch<=122)) {ch=ch-32;} //a-z
				else if ((ch>=64) && (ch<=90)) {;}  //@A-Z
				else if ((ch==45)||(ch==36)) {;} //wildcards - and $
				else if ((ch==',')||(ch==32)) {
					if ((j>0)&&(wordBreaks[j-1]==0)&&(numWordBreaks<MAXNUMWORDS-1)) {wordBreaks[j]=1; numWordBreaks++; ch=',';} //insert , unless was already a wordbreak
					else continue;
				}
				else {
                    continue; //ignore anything else (inc accented characters!
					//=45; //any other char, including space becomes - in iOS
				}
				if (j<MAXPATLENGTH) {thePattern[j]=ch; j++;} else break;
			}
			thePattern[j]=0; 
			if ((j==0)||(wordBreaks[j-1]==0)) wordBreaks[j]=1;
			
			
			newNumWords=0; j=0;
			for (i=0;i<MAXPHRASELENGTH;i++) {
				if (wordBreaks[i]!=0) { 
					[currentDictionary setTheWordLengths:newNumWords :i-j];
					j=i+1; newNumWords++; 
				}
			}
			currentDictionary.theNumWords = newNumWords;
			//nb for an empty pattern this will give theNumWords=1, theWordLengths[0]=0
			
		    currentDictionary.theFullLength = (int)strlen(thePattern);
			currentDictionary.theLength=currentDictionary.theFullLength-currentDictionary.theNumWords+1;
			
			NSMutableString* theLengthStr=[NSMutableString stringWithFormat:@"%d",[currentDictionary theWordLengths:0]];
			
			for (i=1;i<currentDictionary.theNumWords;i++) {
				[theLengthStr appendString:[NSString stringWithFormat:@",%d",[currentDictionary theWordLengths:i]]];
			}
			//trailing comma
			L = currentDictionary.theFullLength;
			if ((L!=0) && (thePattern[L-1]==','))  {[theLengthStr appendString:[NSString stringWithFormat:@","]]; currentDictionary.theLength--;}
            
			self.currNumLettersFieldText = theLengthStr;
			if (L>0) {
                [numLettersField setText:theLengthStr];
                currentDictionary.numLetters = theLengthStr;
            }
            else {
                isProcessing = NO;
                [numLettersField setText:@""]; //and perhaps we have to reprocess to stop 0 length search??
                currentDictionary.numLetters = @"" ;
                return;
            }
            
        self.currPatternFieldText = [NSString stringWithCString:thePattern encoding: NSMacOSRomanStringEncoding];
        //if (![patternField isEditing])
            [patternField setText: self.currPatternFieldText];
        [currentDictionary setPattern:currPatternFieldText];
			
        }
        
        isProcessing = NO;
            
        if ([self OKtoSearch]) [self doSearch];
        
        CFStringRef prefKey = CFSTR("lastPatternPref");
        [self setMyPrefsKey:prefKey toVal:(__bridge CFStringRef)(patternField.text)];
        prefsNeedSaving = YES;

		
    }
	
	else if (sender == anagramField) {
        
        //NSLog(@"anagram field changed");
        
		cStr=(char *)[myText cStringUsingEncoding: NSMacOSRomanStringEncoding];         
		L = (int)strlen(cStr);
		if (L > MAXANAGLENGTH) {L = MAXANAGLENGTH; cStr[L]=0;}
		j=0;
		for (i=0;i<L;i++) {
			ch=cStr[i]; 
			//NOTE we allowing @ and * wildcards in anagram!!!
			if (ch==0) {break;}
			else if ((ch>=97) && (ch<=122)) {
                ch=ch-32; //alphFound = YES;
            } //a-z
			else if ((ch>=64) && (ch<=90)) {;}   //@A-Z
			else if ((ch==45)||(ch==36)) {;} //wildcards - and $
						
			else {continue;} //ignore anything else , inc  ,
		
			theAnagram[j]=ch;
			j++;
		}
		theAnagram[j]=0;
		
        //if no change just return
        anagramFieldChanged = (j != [currentDictionary.anagram length]);
        for (i=0;i<j;i++) {
            if (anagramFieldChanged) break;
            anagramFieldChanged = (theAnagram[i] == [currentDictionary.anagram characterAtIndex:i]);
        }

        if (!anagramFieldChanged) {
            isProcessing = NO;
            return;
        }

		[anagramField setText:[NSString stringWithCString:theAnagram encoding: NSMacOSRomanStringEncoding ]];
        self.currAnagramFieldText = [NSString stringWithCString:theAnagram encoding: NSMacOSRomanStringEncoding];
		[currentDictionary setAnagram:self.currAnagramFieldText];        
        
        //TRY empty string for no letters after editing
        
        if (![anagramField isEditing]) {
            BOOL emptyPattern = YES;
            [anagramField setText:self.currAnagramFieldText];
            for (i=0;i<[self.currAnagramFieldText length]; i++) {
                if (theAnagram[i] != '-') {
                    emptyPattern = NO;
                    break;
                }
            if (emptyPattern) [anagramField setText:@""];
            }
        }
        isProcessing = NO;
        
        //[theTextField setSelectedTextRange:sel];
        
        if ([self OKtoSearch]) [self doSearch];
        
        CFStringRef prefKey = CFSTR("lastAnagramPref");
        [self setMyPrefsKey:prefKey toVal:(__bridge CFStringRef)(anagramField.text)];
        prefsNeedSaving = YES;
        
	}
 	
}

- (BOOL) OKtoSearch {
    BOOL val;
    int i, L, LL;
/*
    if ((currentDictionary.plusFlag)&&([patternField isEditing] ||[anagramField isEditing])) {
        doneTip.hidden = NO;
        return NO;//too slow
    }
    else doneTip.hidden = YES;
*/
    L = (int)[currentDictionary.numLetters length];
    LL = currentDictionary.theFullLength;
	i = (int)[currentDictionary.pattern length];
	
    val = (L>0) && (LL>0);
    //here we try searching when editing
    //val = ![numLettersField isEditing]  && ![patternField isEditing] && ![anagramField isEditing] && (L>0) && (LL>0);
	if (val) {
        if ((LL == 1 ) || ([currentDictionary.numLetters characterAtIndex:L-1] == ',')) {
            val = NO;
        }
        else if ((!lengthlockFlag) && (i<=2) && (currentDictionary.theNumWords > 1)) {
            val = NO;
        }
	}
    
    return val;
}

- (void) doSearch {
    BOOL addWord;
    int i;
    char ch;
    
   // NSLog(@"doSearch called for curr pattern *%@*",currPatternFieldText);
    
    isTrimmed = NO; //ready for next change of pattern
    
    [addDeleteButton setHidden:YES];
    [self showDefinition:NO];
    
	[currentDictionary doSearch];
	if (currentDictionary.errFlag) {
		//set color red
		[resultsField setTextColor:[UIColor redColor]];
		[resultsField setText:currentDictionary.errString];
        gShowingDictionaryList = NO;
		[numResultsLabel setText:[NSString stringWithFormat:@"%d found",0]];
		
	}
    
	else {
		//set color black
		[resultsField setTextColor:[UIColor blackColor]];
		[resultsField setText:currentDictionary.searchResults];
        gShowingDictionaryList = NO;
		[numResultsLabel setText:[NSString stringWithFormat:@"%d found",currentDictionary.numResults]]; //should not hardwire!!
		[resultsField scrollRangeToVisible:NSMakeRange(0,0)];
		
		if ((currentDictionary.numResults == 1) || ([resultsField selectedRange].length>0)) {// selection is always 0 at this point
			[addDeleteButton setTitle:@"Delete" forState:UIControlStateNormal];
			[addDeleteButton setHidden:NO];
            
		}
		else if ((currentDictionary.numResults == 0)&& ([currentDictionary.pattern length]>0)) {
			//if no wild cards in the pattern, then allow to add
            int n = (int)[currentDictionary.pattern length];
            
            addWord = (n==currentDictionary.theFullLength);
            
			for (i=0; i<n; i++) {
				ch = [currentDictionary.pattern characterAtIndex:i];
				addWord = addWord && (((ch>='A') && (ch<='Z'))||((ch==',')&&(currentDictionary.theNumWords>1)&&(i<n-1)));
				if (!addWord) break;
			}
			if (addWord) {
				[addDeleteButton setTitle:@"Add" forState:UIControlStateNormal];
				[addDeleteButton setHidden:NO];
			}
			else [addDeleteButton setHidden:YES];
		}
		//else {
		//	[addDeleteButton setHidden:YES];
		//}
	}
}



- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{ 
	[theTextField resignFirstResponder]; 
	return YES;
}

- (void) setDictionary:(NSString*)dName {
    NSString *numLetters, *pattern, *anagram; //to copy over values
	int theNumWords, theLength, theFullLength, i;
	int theWordLengths[MAXNUMWORDS];
    
    numLetters = currentDictionary.numLetters;
    pattern = currentDictionary.pattern;
    anagram = currentDictionary.anagram;
    theNumWords = currentDictionary.theNumWords;
    theLength = currentDictionary.theLength;
    theFullLength = currentDictionary.theFullLength;
    for (i=0; i<MAXNUMWORDS; i++) {
        theWordLengths[i] = [currentDictionary theWordLengths:i];
    }
        
    self.currentDictionary = [myDictionaryManager dictionaryWithName:dName safetyNet:YES];
    [currentDictionaryButton setTitle:currentDictionary.dictName forState:UIControlStateNormal];
    //for creating launch images - comment out for final
    //[currentDictionaryButton setTitle:@"installing dictionaries ..." forState:UIControlStateNormal];
    
    [plusButton setSelected:currentDictionary.plusFlag];
    currentDictionary.numLetters = numLetters;
    currentDictionary.pattern = pattern;
    currentDictionary.anagram = anagram;
    currentDictionary.theNumWords = theNumWords;
    currentDictionary.theLength = theLength;
    currentDictionary.theFullLength = theFullLength;
    for (i=0; i<MAXNUMWORDS; i++) {
        [currentDictionary setTheWordLengths:i :theWordLengths[i]];
    }

    
    CFStringRef prefKey = CFSTR("dictionary");
    CFStringRef prefVal;
    prefVal = (__bridge CFStringRef)currentDictionary.dictName;
    [self setMyPrefsKey:prefKey toVal:prefVal];
        
   if ([self OKtoSearch])  [self doSearch];
}

- (void)lengthLockTouchDown:(id)sender {
    [self hideDictionaryPicker];
    if (infoViewController) [self dismissInfoView];
    
	self.lengthlockFlag = !lengthlockFlag;
	[lengthLock setSelected:lengthlockFlag];
    
    //pattern needs fixing to fixed length lock
    if (lengthlockFlag) {
        UITextRange * sel = [patternField selectedTextRange];
        int s0 = (int)[patternField offsetFromPosition:[patternField beginningOfDocument] toPosition:sel.start];
        [patternField setText:[self modifyText:[patternField text]]];
        UITextPosition* newStart = [patternField positionFromPosition:[patternField beginningOfDocument] offset:s0];
        [patternField setSelectedTextRange:[patternField textRangeFromPosition:newStart toPosition:newStart]];
    }
    
    
    CFStringRef prefKey = CFSTR("lengthLockFlag");
    CFStringRef prefVal;
    if (lengthlockFlag) prefVal = CFSTR("Locked");
    else prefVal = CFSTR("Unlocked");
    [self setMyPrefsKey:prefKey toVal:prefVal];
}

- (void)plusButtonTouchDown:(id)sender {
    [self hideDictionaryPicker];
    if (infoViewController) [self dismissInfoView];
    
	currentDictionary.plusFlag = !currentDictionary.plusFlag;
	[plusButton setSelected:currentDictionary.plusFlag];
	
    if ([self OKtoSearch]) [self doSearch];
}

- (void)addDeleteButtonTouchDown:(id)sender {
	NSString *alertMessage, *theTitle;
    
    [self hideDictionaryPicker];

	theTitle = [sender currentTitle];
	alertMessage = [NSString stringWithFormat:@"Are you sure you want to %@ this word/phrase/selection?",[theTitle lowercaseString]];
	// open a alert with an OK and cancel button
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:theTitle message:alertMessage
                                        delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	[alert show];
}

- (void) lookupTouchDown:(id)sender {
    
    //to dismiss the keyboard
    [self.view endEditing:YES];

    [self showInfoView:gSelString];
}

- (void) alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger) i {
	int n;
	NSString *whichAlert;
        
	if (i==1) { 
		whichAlert = [theAlert title];
		
		//what to add/delete - if no selection, either add pattern or delete single entry in searchResults
		if ([whichAlert isEqualToString:@"Add"]) {
			n=[currentDictionary addWord];
			[theAlert dismissWithClickedButtonIndex:i animated:YES];
		//display dialog showing num added
			if ((n==0) || currentDictionary.errFlag) {
				[resultsField setTextColor:[UIColor redColor]];
				[resultsField setText:currentDictionary.errString];
                gShowingDictionaryList = NO;
				[numResultsLabel setText:@""];
                [self showDefinition:NO];
				[addDeleteButton setHidden:YES];
			}
			else {
				[resultsField setTextColor:[UIColor blueColor]];
				[resultsField setText:currentDictionary.errString];
                gShowingDictionaryList = NO;
				[numResultsLabel setText:@""];
                [self showDefinition:NO];
				[addDeleteButton setHidden:YES];
			}
		}
		
		else if ([whichAlert isEqualToString:@"Delete"]) {
			[theAlert dismissWithClickedButtonIndex:i animated:YES];
			if ([currentDictionary numResults]==1){
				n=[currentDictionary deleteWords:currentDictionary.searchResults];
			}
			else {
				NSMutableString* dString = [NSMutableString stringWithString:[currentDictionary.searchResults substringWithRange:[resultsField selectedRange]]];
                n=[currentDictionary deleteWords:dString];
			}
			//display dialog showing num deleted
			if ((n==0) || currentDictionary.errFlag) {
				[resultsField setTextColor:[UIColor redColor]];
				[resultsField setText:currentDictionary.errString];
                gShowingDictionaryList = NO;
				[numResultsLabel setText:@""];
				[addDeleteButton setHidden:YES];
                [self showDefinition:NO];
			}
			else {
				[resultsField setTextColor:[UIColor blueColor]];
				[resultsField setText:currentDictionary.errString];
                gShowingDictionaryList = NO;
				[numResultsLabel setText:@""];
				[addDeleteButton setHidden:YES];
                [self showDefinition:NO];
			}
		}
		else {
			[theAlert dismissWithClickedButtonIndex:i animated:YES];
		}
	}
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

#pragma mark -
#pragma mark Dictionary picker stuff

- (IBAction) chooseDictionary:(id)sender{
    [self.view endEditing:YES];
    if (!dictPicker.hidden) {
        [self hideDictionaryPicker];
    }  
    else {
        if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].length > 0) [currentDictionaryButton setHidden:YES];
        [dictPicker setHidden:NO];
        [dictPicker selectRow:currentDictionary.installedRowNumber inComponent:0 animated:YES];
    }
    
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    int i;
    int n = (int)[myDictionaryManager.theDictionaries count];
    MyDictionaryObject* newDict;
    
    for (i=0; i<n; i++) {
        newDict = [myDictionaryManager.theDictionaries  objectAtIndex:i];
        if (newDict.installedRowNumber == row) break;
    }
    
    if (i==n) {
        NSLog(@"pickerview error");
        return;
    }
    
    //copy over the existing search settings
    newDict.numLetters = currentDictionary.numLetters;
    newDict.pattern = currentDictionary.pattern;
    newDict.anagram = currentDictionary.anagram;
    newDict.theNumWords = currentDictionary.theNumWords;
    newDict.theLength = currentDictionary.theLength;
    newDict.theFullLength = currentDictionary.theFullLength;

    for (i=0;i<MAXNUMWORDS;i++) [newDict setTheWordLengths:i :[currentDictionary theWordLengths:i]];
    
    [self hideDictionaryPicker];
    //self.currentDictionary = newDict;        
    //[currentDictionaryButton setTitle:currentDictionary.dictName forState:UIControlStateNormal];

    //if ([self OKtoSearch]) [self doSearch];
    
    [self setDictionary:newDict.dictName];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    //return [dictPicker rowSizeForComponent:component].height;
    return 50.0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    int i;
    int n = (int)[myDictionaryManager.theDictionaries  count];
    MyDictionaryObject* aDict;
             
    for (i=0; i<n; i++) {
        aDict = [myDictionaryManager.theDictionaries  objectAtIndex:i];
        if (aDict.installedRowNumber == row) break;
    }
    
    if (i==n) {
        NSLog(@"pickerview setup error");
        return @"error";
    }

    
    return aDict.dictName;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 220.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    
    return [myDictionaryManager numberOfInstalledDictionaries];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
   
    return 1;
}

- (void) checkVersion {
    //CFBundleRef mainBundle;
    //would be better to use
    NSString* appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    //??
    //rather than have to update this each time in multiple places (project, SettingsBundl, prefs
    //altho did have the advantage of knowing if actually a newer version
    /*
                // Get the main bundle for the app
                mainBundle = CFBundleGetMainBundle();
                // This is the ‘vers’ resource style value for 1.0.0
                #define kMyBundleVersion1 0x01008000
                
                UInt32  bundleVersion, oldVersion; //for version 1 this was 17858560
                
                // Look for the bundle’s version number.
                bundleVersion = CFBundleGetVersionNumber(mainBundle);
                
               // NSLog(@"bundleVersion is %lu",bundleVersion);
                
                CFStringRef prefKey = CFSTR("version");
                CFStringRef prefVal;    
                prefVal = (CFStringRef)CFPreferencesCopyAppValue(prefKey,
                                                                 kCFPreferencesCurrentApplication);
                if (prefVal == nil) {
                    oldVersion = 0;
                }
                else  {
                    oldVersion = [(__bridge NSString*)prefVal integerValue];
                    CFRelease(prefVal);
                }
                
                NSLog(@"appversion %@, prefVal %@, bundleVersion %d, oldversion %d",appVersion,prefVal,(unsigned int)bundleVersion,(unsigned int)oldVersion);
                if (bundleVersion > oldVersion) {
    */
    NSString* oldVersion;
    CFStringRef prefKey = CFSTR("version");
    CFStringRef prefVal;
    prefVal = (CFStringRef)CFPreferencesCopyAppValue(prefKey,
                                                     kCFPreferencesCurrentApplication);
    if (prefVal == nil) {
        oldVersion = @"";
    }
    else  {
        oldVersion = (__bridge NSString*)prefVal;
        CFRelease(prefVal);
    }

    if (![appVersion isEqualToString:oldVersion]) {
        self.newVersion = YES;
        //write the bundleversion in prefs
        prefVal = (__bridge CFStringRef)appVersion;
        [self setMyPrefsKey:prefKey toVal:prefVal];
 

    }
    else {
        self.newVersion = NO;
    }
    
    //NSLog(@"force new app version so dicts are installed"); //for testing new version
    //self.newVersion = YES;
    
    
}

#pragma mark -
#pragma mark menuButton


- (IBAction) infoButton:(id)sender {
    [self hideDictionaryPicker];
    if (infoViewController) {
        [self dismissInfoView];
        return;
    }
    
    [self.view endEditing:YES];
    
   
    NSInteger deviceVersion = [[UIDevice currentDevice] systemVersion].integerValue;
    
    if (deviceVersion < 8) { //for system<8, UIActionSheet works //for 8 and higher depreceated will work but lots of NSLog messages about snapshots for unrendered objects - possibly bug but better to avoid
        if (menuSheet) {
            menuSheet = nil;
        }
        
        NSString* changesStr, *downloadStr;
        if (dictionaryUpdateAvailable) {
            changesStr = @"Changes !";
            downloadStr = @"Download new dictionary !";
        }
        else {
            changesStr = @"Changes";
            downloadStr = @"Download new dictionary";
        }

        //bring up menu versions,  Dictionary Stats, Download new dictionary
        menuSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil
                        destructiveButtonTitle:nil otherButtonTitles:@"Statistics", changesStr,@"Installed dictionaries",@"Install/Remove...",downloadStr,@"Help",nil];
        
        //[menuSheet setNeedsLayout];
        //[menuSheet layoutIfNeeded];
        
        //[self performSelector:@selector(doDelayedMenu) withObject:nil afterDelay:0.3];
        
        [menuSheet showFromRect:[infoButton frame] inView:self.view animated:YES];
    }
    else {
        [self doMenuSheetAlert];
        
    }
}

- (void) doMenuSheetAlert {
    NSString* changesStr, *downloadStr;
    __weak MyViewController* blockSelf = self;
    
    if (dictionaryUpdateAvailable) {
        changesStr = @"Changes !";
        downloadStr = @"Download new dictionary !";
    }
    else {
        changesStr = @"Changes";
        downloadStr = @"Download new dictionary";
    }
    menuController = nil;
    
    menuController = [UIAlertController alertControllerWithTitle:nil message:nil
                                         preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* action0 = [UIAlertAction actionWithTitle:@"Statistics" style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {[blockSelf doActionItem:0];}];
    [menuController addAction:action0];
    UIAlertAction* action1 = [UIAlertAction actionWithTitle:changesStr style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {[blockSelf doActionItem:1];}];
    [menuController addAction:action1];
    UIAlertAction* action2 = [UIAlertAction actionWithTitle:@"Installed dictionaries" style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {[blockSelf doActionItem:2];}];
    [menuController addAction:action2];

    UIAlertAction* action3 = [UIAlertAction actionWithTitle:@"Install/Remove..." style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {[blockSelf doActionItem:3];}];
    [menuController addAction:action3];
    
    UIAlertAction* action4 = [UIAlertAction actionWithTitle:downloadStr style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {[blockSelf doActionItem:4];}];
    [menuController addAction:action4];
    
    UIAlertAction* action5 = [UIAlertAction actionWithTitle:@"Help" style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {[blockSelf doActionItem:5];}];
    [menuController addAction:action5];
    
    menuController.popoverPresentationController.sourceView = self.view;
    menuController.popoverPresentationController.sourceRect = [infoButton frame];
    
    alertSheetPresentationController = menuController.popoverPresentationController;
    alertSheetPresentationController.delegate = (id)self;
    
    [menuController.view layoutIfNeeded];
    
    menuSheetActive = YES;
    [self presentViewController:menuController animated:YES completion:nil];
    

}
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    if (popoverPresentationController == alertSheetPresentationController) {
        menuSheetActive = NO;
        menuController = nil;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == menuSheet) {
        menuSheet = nil;
        menuSheetActive = NO;
    }
}

- (void) showDictionaryList {
    NSString* theText = [myDictionaryManager versions];
    [resultsField setFont:[UIFont fontWithName:@"CourierNewPS-BoldMT" size:18.0]];
    [resultsField setTextColor:[UIColor blueColor]];
    [resultsField setText:theText];
    gShowingDictionaryList = YES;
    [numResultsLabel setText:@""];
    [self showDefinition:NO];
}

- (void) showChanges {
    NSString* theText = [myDictionaryManager changes];
    [resultsField setFont:[UIFont fontWithName:@"CourierNewPS-BoldMT" size:18.0]];
    [resultsField setTextColor:[UIColor blueColor]];
    [resultsField setText:theText];
    gShowingDictionaryList = NO;
    [numResultsLabel setText:@""];
    [self showDefinition:NO];

}

- (void) actionSheet:(UIActionSheet*)menu  clickedButtonAtIndex:(NSInteger) i {
    [self doActionItem:i];
}

//- (void) actionSheet:(UIActionSheet*)menu  clickedButtonAtIndex:(NSInteger) i {

- (void) doActionItem:(NSInteger) i {
    NSString * theText;
    SelectionTableController * myTable;
    
    //NSLog(@"user selected %@",[menu buttonTitleAtIndex:i]);
    
    switch (i) {
        case 0: //statistics
            theText = [currentDictionary statistics];
            [resultsField setFont:[UIFont fontWithName:@"CourierNewPS-BoldMT" size:18.0]];
            [resultsField setTextColor:[UIColor blueColor]];
            [resultsField setText:theText];
            gShowingDictionaryList = NO;
            [numResultsLabel setText:@""];
            [self showDefinition:NO];
            break;
        case 1: //changes
            [self showChanges];
            break;
        case 2: //installed dictionaries
            [self showDictionaryList];
            break;
            
        case 3: //remove/reinstall dictionary
            if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].length > 0) { //in landscape under iOS7 opens with portrait??
                myTable = [[SelectionTableController alloc] initWithNibName:@"SelectionTable_iPad" bundle:nil];
                [myTable.view setFrame:self.view.bounds];
                [self.view addSubview:myTable.view];
            }
            else {
                myTable = [[SelectionTableController alloc] initWithNibName:@"SelectionTable_iPhone" bundle:nil];
                [myTable.view setFrame:self.view.bounds];
                [self.view addSubview:myTable.view];
            }
            
            self.mySelectionTableController = myTable; //seems to be necessary to retain
            [myTable assignMyViewController:self kind:0]; //if done before addView, iPhone has 0 items in toolbar , presum view is still loading
            
           break;
        case 4: //download
            if ([MyViewController hasConnectivity]>0) {
                [self oopsAlert:@"Online Dictionaries" message:@"Sorry, You are not connected to the internet"];
                return;
            }
            
            if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].length > 0) { //in landscape under iOS7 opens with portrait??
                myTable = [[SelectionTableController alloc] initWithNibName:@"SelectionTable_iPad" bundle:nil];
                [myTable.view setFrame:self.view.bounds];
                [self.view addSubview:myTable.view];
            }
            else {
                myTable = [[SelectionTableController alloc] initWithNibName:@"SelectionTable_iPhone" bundle:nil];
                [myTable.view setFrame:self.view.bounds];
                [self.view addSubview:myTable.view];
            }
            
            self.mySelectionTableController = myTable; //seems to be necessary to retain
            [myTable assignMyViewController:self kind:1]; //if done before addView, iPhone has 0 items in toolbar , presum view is still loading

            break;
        case 5: //help
            [self showInfoView:nil];
            //[self asyncShowInfo]; //attempt to suppress log messages about _BSMachError:(os/kern) invalid capability
            break;
        default:
            break;
    }
   
}
/*
- (void) asyncShowInfo {
    __weak MyViewController* blockSelf = self;
    dispatch_after(0.2,dispatch_get_main_queue(), ^{
        [blockSelf showInfoView:nil];
    });
}
*/

- (void) dismissSelectionTable {
    [mySelectionTableController.view removeFromSuperview];
}

#pragma mark -
#pragma mark user alert

- (void) oopsAlert:(NSString*)aTitle message:(NSString*)aMessage {
	UIAlertView * oopsAlert = [[UIAlertView alloc] initWithTitle: aTitle message:aMessage delegate: nil 
                                            cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [oopsAlert show];
}

#pragma mark -
#pragma mark gestures

- (void)addGestureRecognizersToView:(UIView *)theView
{
   
	if (theView == self.resultsField) {
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPiece:)];
		[tapGesture setNumberOfTapsRequired:1];
		[tapGesture setDelegate:self];
		[theView addGestureRecognizer:tapGesture];
		return;
		
	}
}

- (void) tapPiece:(UITapGestureRecognizer *)gestureRecognizer {            
    if (infoViewController) [self dismissInfoView];
    
    if ([gestureRecognizer view]==self.resultsField) {
        [self hideDictionaryPicker];
        
    }
    
    
}

#pragma mark -
#pragma device rotation


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    //fix the popover for iPad
    if ((menuSheet)&&(!menuSheet.hidden)&&([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].length > 0)){
        //[menuSheet setHidden:YES];
        [menuSheet dismissWithClickedButtonIndex:0 animated:NO];
        [self performSelector:@selector(infoButton:) withObject:self afterDelay:coordinator.transitionDuration];
    }
    else if (menuController && alertSheetPresentationController) {
        [menuController dismissViewControllerAnimated:NO completion:^(void){menuSheetActive = NO;}];
        [self performSelector:@selector(infoButton:) withObject:self afterDelay:coordinator.transitionDuration];
    }
}

#pragma mark -
#pragma infoView

- (void) showInfoView:(NSString*)selString {
    InfoViewController* aController;
    
	if (infoViewController == nil) {		
        if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].length > 0)
            aController = [[InfoViewController alloc] initWithNibName:@"InfoView_iPad" bundle:nil];
        else 
            aController = [[InfoViewController alloc] initWithNibName:@"InfoView_iPhone" bundle:nil];
        
        self.infoViewController = aController;

		infoViewController.callingController = self;
                
		[self.view addSubview:infoViewController.view];
        
        if (selString) {
            //set up the buttons etc
            [infoViewController.lang setSelectedSegmentIndex:gLang];
            [infoViewController.engType setSelectedSegmentIndex:gEnglishType];

            [infoViewController.urlType setSelectedSegmentIndex:gURL];
            if (gURL == kDictionary) {
                [infoViewController.lang setHidden:YES];
                [infoViewController.engType setHidden:NO];
            }
            else if (gURL == kOnelook) {
                [infoViewController.lang setHidden:YES];
                [infoViewController.engType setHidden:YES];
            }
            else {
                [infoViewController.lang setHidden:NO];
                [infoViewController.engType setHidden:YES];
            }

        }
        else {
            infoViewController.webControls.hidden = YES;
            CGRect myFrame = infoViewController.userManualView.frame;
            myFrame.origin.y = 13;
            myFrame.size.height = infoViewController.view.bounds.size.height - 26;
            [infoViewController.userManualView setFrame:myFrame]; 
        }
		//slide into place
		CGRect newFrame = infoViewController.view.frame;
		newFrame.origin.y = 100;
		[UIView animateWithDuration:0.5 animations:^{
			[self.infoViewController.view setFrame:newFrame];
		}];
    }
    
    if (selString) {
        [self doLookup];
    }
    else
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [infoViewController.userManualView loadRequest:[NSURLRequest
//                                                            requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"userManual" ofType:@"html"]isDirectory:NO]]];
//        });
        [infoViewController.userManualView loadRequest:[NSURLRequest
                requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"userManual" ofType:@"html"]isDirectory:NO]]];
}

- (void) dismissInfoView {
    if (infoViewController) {
        //slide out then on completion
        
        CGRect newFrame = infoViewController.view.frame;
		newFrame.origin.y = self.view.frame.size.height;
		[UIView animateWithDuration:0.5 animations:^{
			[self.infoViewController.view setFrame:newFrame];
		}
         completion:^(BOOL finished) {
             [self.infoViewController.view removeFromSuperview];
             self.infoViewController = nil;
             [self showDefinition:NO];
             
             [self.resultsField setEditable:NO]; //this to fix a bug I think in WebView - on closing infoView becomes editable????
             //actually probably caused by my call setSelectedRange to 0,0 -
         } 
        ];

        
    }
}

- (void) doLookup {
        
    NSString* theString;
    
    switch (gURL) {
        case kDictionary:
            theString = [dictStr stringByReplacingOccurrencesOfString:@"*" withString:gSelString];
            if (gEnglishType == kBritishEnglish)
                {theString = [theString stringByReplacingOccurrencesOfString:@"$" withString:@"english"];}
            else
                {theString = [theString stringByReplacingOccurrencesOfString:@"$" withString:@"american"];}
            break;
        case kWiki:
            theString = [wikiStr stringByReplacingOccurrencesOfString:@"*" withString:gSelString];
            break;
        case kGoogle:
            theString = [googleStr stringByReplacingOccurrencesOfString:@"*" withString:gSelString];
            break;
        case kOnelook:
            theString = [onelookStr stringByReplacingOccurrencesOfString:@"*" withString:gSelString];
            break;
        case kUser:
            theString = [userURLStr stringByReplacingOccurrencesOfString:@"*" withString:gSelString];
            break;
            
        default:
            theString = @"";
            break;
    }
    
    switch (gLang) {
        case kEnglish:
            theString = [theString stringByReplacingOccurrencesOfString:@"!" withString:@"en"];
            break;
        case kItalian:
            theString = [theString stringByReplacingOccurrencesOfString:@"!" withString:@"it"];
            break;
        case kGerman:
            theString = [theString stringByReplacingOccurrencesOfString:@"!" withString:@"de"];
            break;
        case kFrench:
            theString = [theString stringByReplacingOccurrencesOfString:@"!" withString:@"fr"];
            break;
        case kSpanish:
            theString = [theString stringByReplacingOccurrencesOfString:@"!" withString:@"es"];
            break;
        case kDutch:
            theString = [theString stringByReplacingOccurrencesOfString:@"!" withString:@"nl"];
            break;
            
        default:
            break;
    }

    [resultsField setSelectedRange:NSMakeRange(0,0)];
    [resultsField setEditable:NO]; //I think the above line is causing resultsField to become editable.
    
    [infoViewController.urlInput setText:theString];
    [infoViewController.userManualView loadRequest:[NSURLRequest 
            requestWithURL:[NSURL URLWithString:theString]]];    

    
}

- (void) putLang:(NSNumber*)num{
    gLang = [num intValue];
    //and set pref
    CFStringRef prefKey = CFSTR("languagePref");
    CFStringRef prefVal;
    prefVal = (__bridge CFStringRef)[NSString stringWithFormat:@"%d",gLang];
    [self setMyPrefsKey:prefKey toVal:prefVal];
    
    prefsNeedSaving = YES;
    
    [self doLookup];
    
}

- (void) putEngType:(NSNumber*)num{
    gEnglishType = [num intValue];
    //and set pref
    CFStringRef prefKey = CFSTR("englishTypePref");
    CFStringRef prefVal;
    prefVal = (__bridge CFStringRef)[NSString stringWithFormat:@"%d",gEnglishType];
    [self setMyPrefsKey:prefKey toVal:prefVal];
    
    prefsNeedSaving = YES;
    
    [self doLookup];
 
}


- (void) putURLType:(NSNumber*)num{
    gURL = [num intValue];
    
    
    if (gURL == kDictionary) {
        [infoViewController.lang setHidden:YES];
        [infoViewController.engType setHidden:NO];
    }
    else if (gURL == kOnelook) {
        [infoViewController.lang setHidden:YES];
        [infoViewController.engType setHidden:YES];
    }
    else {
        [infoViewController.lang setHidden:NO];
        [infoViewController.engType setHidden:YES];
    }

    //and set pref
    CFStringRef prefKey = CFSTR("urlTypePref");
    CFStringRef prefVal;
    prefVal = (__bridge CFStringRef)[NSString stringWithFormat:@"%d",gURL];
    [self setMyPrefsKey:prefKey toVal:prefVal];
    if (gURL == kUser) {
        prefKey = CFSTR("userURLPref");
        NSString* theURLString = infoViewController.urlInput.text;
        
        if ([theURLString length]==0) {
            [self setMyPrefsKey:prefKey toVal:NULL];
        }
        else {
            theURLString = [theURLString  stringByReplacingOccurrencesOfString:gSelString withString:@"*"];
            prefVal = (__bridge CFStringRef)[NSString stringWithFormat:@"%d",gLang];
            [self setMyPrefsKey:prefKey toVal:prefVal];
        }
    }
    
    prefsNeedSaving = YES;

    [self doLookup];
}

- (void) putUserURL:(NSString*)urlString {
    
    CFStringRef prefKey = CFSTR("urlTypePref");
    CFStringRef prefVal;
    
    //first the urlTypePref
    prefVal = (__bridge CFStringRef)[NSString stringWithFormat:@"%d",gURL];
    [self setMyPrefsKey:prefKey toVal:prefVal];
    
    //next set user url or default
    prefKey = CFSTR("userURLPref");
    
    if ([urlString length] == 0) {
        [self setMyPrefsKey:prefKey toVal:NULL];
        userURLStr = defUserStr;
    }
    
    if ([urlString characterAtIndex:0] == 'd') { //d set to merriam-webster
        urlString = altdUserString;
        prefVal = (__bridge CFStringRef)urlString;
        [self setMyPrefsKey:prefKey toVal:prefVal];
        userURLStr = urlString;
    }
    
    if ([urlString characterAtIndex:0] == 'b') { //d set to brittannica
        urlString = altbUserString;
        prefVal = (__bridge CFStringRef)urlString;
        [self setMyPrefsKey:prefKey toVal:prefVal];
        userURLStr = urlString;
    }
    else if ([urlString characterAtIndex:0] != 'h') { //to reset the default value, enter anything not starting with h
        [self setMyPrefsKey:prefKey toVal:NULL];
        userURLStr = defUserStr;
    }
    else {
        //only allow https: ? but pre ios9 users are ok with http:
        //urlString = [urlString  stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
        urlString = [urlString  stringByReplacingOccurrencesOfString:gSelString withString:@"*"];
        prefVal = (__bridge CFStringRef)urlString;
        [self setMyPrefsKey:prefKey toVal:prefVal];
        userURLStr = urlString;
    }
    
    prefsNeedSaving = YES;    
    
    [self doLookup];

    
}
/*
- (void) keyboardDidDismiss {
    doneTip.hidden = YES;
}

- (void) keyboardWillAppear {
    //if editing pattern or anagram in plusFlag mode briefly show the doneTip
    if ((currentDictionary.plusFlag)&&((patternField.isEditing)||(anagramField.isEditing))) {
        doneTip.hidden = NO;
    }
}
*/
- (void) setMyPrefsKey:(CFStringRef)prefKey toVal:(CFStringRef) prefVal {    
    CFPreferencesSetAppValue(prefKey, prefVal,
                         kCFPreferencesCurrentApplication);
    // Write out the preference data. //this should only be done when going into b/g
    prefsNeedSaving = YES;
}

+ (int) hasConnectivity; {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    int val = 1; //0 for OK, 1 for not connected, 2 for no internet or server not responding
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    if(reachability != NULL) {
        //NetworkStatus retVal = NotReachable;
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
            {
                // if target host is not reachable
                CFRelease(reachability);
                return 1;
            }
            
            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
            {
                // if target host is reachable and no connection is required
                //  then we'll assume (for now) that your on Wi-Fi
                val = 0;  //skip next tests
                //return YES;
            }
            
            if (val != 0) {
                if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
                     (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
                {
                    // ... and the connection is on-demand (or on-traffic) if the
                    //     calling application is using the CFSocketStream or higher APIs
                    
                    if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
                    {
                        // ... and no [user] intervention is needed
                        //return YES;
                        val = 0;
                    }
                }
            }
            
            if (val != 0) {
                if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
                {
                    // ... but WWAN connections are OK if the calling application
                    //     is using the CFNetwork (CFSocketStream?) APIs.
                    //return YES;
                    val = 0;
                }
            }
        }
    }
    
    CFRelease(reachability);
    
    return val;
    //foll is a check if internet actually available on the network - but it hangs FC until timeout
    //why not let Safari hang, user can always quit it and continue with FC
    //if (val != 0) {
    //    return val;
    //}
/*
    val = 2;
    SCNetworkReachabilityRef reachability2 = SCNetworkReachabilityCreateWithName(NULL,[@"www.google.com" UTF8String]);
    if (reachability2 != NULL) {
        //NetworkStatus retVal = NotReachable;
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
            {
                // if target host is not reachable
                CFRelease(reachability2);
                return 2;
            }
            
            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
            {
                // if target host is reachable and no connection is required
                //  then we'll assume (for now) that your on Wi-Fi
                val = 0;  //skip next tests
                //return YES;
            }
            
            if (val != 0) {
                if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
                     (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
                {
                    // ... and the connection is on-demand (or on-traffic) if the
                    //     calling application is using the CFSocketStream or higher APIs
                    
                    if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
                    {
                        // ... and no [user] intervention is needed
                        //return YES;
                        val = 0;
                    }
                }
            }
            
            if (val != 0) {
                if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
                {
                    // ... but WWAN connections are OK if the calling application
                    //     is using the CFNetwork (CFSocketStream?) APIs.
                    //return YES;
                    val = 0;
                }
            }
        }
    }
    
    CFRelease(reachability2);
    return val;
 */
}

- (NSString*) myUniqueID {
    CFStringRef prefKey = CFSTR("appIDPref");
    CFStringRef prefVal;
    NSString * str;
    //if a pref for the appID exists, get it;
    prefVal = (CFStringRef)CFPreferencesCopyAppValue(prefKey,
                                                     kCFPreferencesCurrentApplication);
    if (prefVal == nil) {
        //else create a random 16 digit number, return as string
        unsigned int q = 100000000 + arc4random();
        unsigned int qq = arc4random();
        str = [NSString stringWithFormat:@"%u%u",q,qq];
        
        //and save this as a pref
        prefVal = (__bridge CFStringRef)[NSString stringWithFormat:@"%@",str];
        [self setMyPrefsKey:prefKey toVal:prefVal];

    }
    
    str = (__bridge NSString*)(prefVal);
    
    return str;
}


@end
