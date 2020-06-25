//
//  MyDictionaryObject.h
//  CAiOS
//
//  Created by Neville Smythe on 8/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//can we put these into a common header?
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

#define MAXHITDISPLAY 500
//this shoud be a preference??

#import <Foundation/Foundation.h>

@class DictionaryManager;


@interface MyDictionaryObject : NSObject <NSCoding>{
	DictionaryManager * myDictionaryManager;
    
	NSString *dictName, *dictPath, *sourcePath;
    float version;
    
	NSString *numLetters, *pattern, *anagram; //in CA these are NSMutableString, char[MAX...]
	int theNumWords, theLength, theFullLength;
	int theWordLengths[MAXNUMWORDS];
	BOOL plusFlag, searchFlag, userSupplied, userDeleted, userModified;
	NSMutableString *searchResults;
	int numResults;
    int entryNumber; //the objectIndex in theDictionaries
    int installedRowNumber, removedRowNumber; // rows in menus; update with updateDictionaryRows

}

@property float version;

@property (nonatomic,strong) NSString *numLetters;
@property (nonatomic,strong) NSString *pattern;
@property (nonatomic,strong) NSString *anagram;
@property (nonatomic,strong) NSString *dictName;
@property (nonatomic,strong) NSString *dictPath;
@property (nonatomic,strong) NSString *sourcePath;
@property (nonatomic,strong) NSMutableString *searchResults;

@property (nonatomic,strong) DictionaryManager * myDictionaryManager;

@property int theNumWords;
@property int theLength;
@property int theFullLength;
@property int numResults;
@property BOOL plusFlag;
@property BOOL userSupplied;
@property BOOL userDeleted, userModified;
@property BOOL errFlag;
@property (nonatomic,strong) NSString *errString;
@property int entryNumber, installedRowNumber, removedRowNumber;

- (id)initWithName: (NSString*)theName path:(NSString*) path version: (float) v  userSupplied:(BOOL)user source:(NSString*) source dictionaryManager:(DictionaryManager*)dM;

- (void) setTheWordLengths: (int) i : (int) j;
- (int) theWordLengths:(int)i;
//- (void) setupDictionary: (NSString*)newDictionaryName;
- (void) doSearch;
- (int) addWord;
- (int) deleteWords:(NSMutableString *)dString;
- (NSMutableString*) statistics;

- (int) dictionaryContainsEntry:(NSString*)entry adding:(BOOL)add deleting:(BOOL) del;


@end
