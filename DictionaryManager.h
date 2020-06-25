//
//  DictionaryManager.h
//  CAiOS
//
//  Created by Neville Smythe on 10/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//constructs array/menulist of installed dictionaries, moves them to library, unpack and moves user 
//dictionaries, remove and restore dictionaries

#import <UIKit/UIKit.h>
#import "MyDictionaryObject.h"

@interface DictionaryManager  : NSObject <UIAlertViewDelegate> {
    NSMutableArray * theDictionaries;//the array of installed dictionaries
    NSMutableArray * exLibraryDictionaries; //array of paths of dictionary folders in the bundle!! (not dictionaries!)
    NSString * dictionariesDirectory; //the Library subdirectory (prob this does not be need to public)
    UIAlertView * downloadAlert;
    BOOL needsArchiving;
    
    NSMutableArray* userChanges, *serverDictionaryArray;

}

- (DictionaryManager*) initWithViewController:(id)controller; // just in case we need a callback

//- (void) installUserChangesFiles; // no longer used, instead we keep an archived array in the library
- (BOOL) moveBundledDictionaryToLibrary:(NSString*)path;
- (BOOL) moveUserDictionaryToLibrary:(NSString*)path;
- (BOOL) doImportDictionary:(NSString *) dictName fromPath:(NSString *) CAdictPath version:(float)v;
- (void) removeDictionaryFromLibrary: (MyDictionaryObject*)dict;
- (void) updateDictionaryArray;
- (void) archiveDictionaries;
- (NSMutableString*) versions;
- (NSMutableString*) changes;

- (int) numberOfInstalledDictionaries;
- (int) numberOfRemovedDictionaries;
- (void) updateDictionaryRows;

- (MyDictionaryObject*) dictionaryWithName:(NSString*)dName safetyNet:(BOOL)sf;

- (void) setBackupAttributeOfItemAtPath:(NSString *)path skipBackup:(BOOL)bb;

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;

- (void) downLoadAndInstall:(NSString*) dName;
- (void) downLoadAndInstall2:(NSString*) dName;

- (void) addUserChange:(NSString*)entryStr forDictionary:(NSString*)dictStr
              withDate:(NSString*)   dateStr adding:(BOOL)add;
- (void) sendChange:(NSMutableDictionary*) theChange;

- (int) compareServerVersions:(NSMutableString*) str;
- (void) downloadServeDictArrayAsynch;

- (void) purgeChanges:(NSString *) dictName old:(BOOL) old;
- (void) removeChanges:(NSString *) dictName;


//@property (nonatomic,strong) MyDictionaryObject * defaultDictionary;//now prop of myViewController
@property (nonatomic,strong) NSString * dictionariesDirectory;
@property (nonatomic,strong) NSMutableArray * theDictionaries, * exLibraryDictionaries;
@property (nonatomic,strong) UIAlertView * downloadAlert;
@property (nonatomic,strong) NSMutableArray* userChanges, * serverDictionaryArray;
@property BOOL needsArchiving;


@end
