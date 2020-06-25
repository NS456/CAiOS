//
//  DictionaryManager.m
//  CAiOS
//
//  Created by Neville Smythe on 10/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DictionaryManager.h"
#import "MyViewController.h"

const NSString * dictStringURL = @"http://nmsmythe.id.au/CAiOS/Dictionaries";

@implementation DictionaryManager {
    MyViewController * viewController;
    NSString * resourcePath, *installedDictionariesPath, *userDocsPath;
    NSFileManager * defManager;
    NSString * archivePath, *userChangesArchivePath;
    NSDateFormatter *dateFormatter;
    BOOL userChangesFromOldStyle;

}

@synthesize dictionariesDirectory;
@synthesize theDictionaries, exLibraryDictionaries;
@synthesize downloadAlert;
@synthesize needsArchiving;
@synthesize userChanges, serverDictionaryArray;



- (DictionaryManager*) initWithViewController:(id)controller{
    self = [super init];
    viewController = controller;
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    //create some required file paths
    
    defManager = [NSFileManager defaultManager];
    BOOL isDir;
    
    needsArchiving = NO;
    
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES); //NSLibraryDirectory
    if ([paths count]>0) {
        self.dictionariesDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"CADictionaries"];
        archivePath = [dictionariesDirectory stringByAppendingPathComponent:@"CAArchive"];
        userChangesArchivePath = [dictionariesDirectory stringByAppendingPathComponent:@"CAChangesArchive"];
        
    }
    else {
        NSLog(@"Fatal error; cannot get User Library path! Should not happen");
        self.dictionariesDirectory = nil; //will cause a crash; should have user alert, and Quit!!!!
    }
    
    
    resourcePath = [[NSBundle mainBundle] resourcePath]; //this is the path for Resources
    installedDictionariesPath = [resourcePath stringByAppendingPathComponent:@"Dictionaries"];
    
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([paths count]>0) {
        userDocsPath = [paths objectAtIndex:0];
    }
    else {userDocsPath = nil;}
    
    NSMutableArray* anArray = [NSMutableArray arrayWithCapacity:10];
    self.serverDictionaryArray = anArray;
    
    userChangesFromOldStyle = NO;
    [self setupUserChanges]; //do this now so we can reinstall user corrections in new libraries
    //does theDictionaries exist -- if so unarchive it; if launching a new update skip to else
    
    
    //in prev version, dictionary "version" was incorrectly encoded as an int!!!
    //so this version (1.2.0) should purge the archive to enforce reinstalling dictionaries
    if (([(MyViewController*)controller newVersion]) && ([defManager fileExistsAtPath:archivePath isDirectory:&isDir])) {
        NSString* appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if ([appVersion isEqualToString:@"1.2.0"]) {
            [defManager removeItemAtPath:archivePath error:nil];
            //NSLog(@"faulty archive removed");
        }
    }
    
    
    if ((![(MyViewController*)controller newVersion]) && ([defManager fileExistsAtPath:archivePath isDirectory:&isDir])) {
        
        self.theDictionaries = [NSKeyedUnarchiver unarchiveObjectWithFile:archivePath];
        needsArchiving = NO;
        
        //and check if any user dictionaries have become available
        
        [self updateDictionaryArray];
        
        //finally purge changes for all dicts -only really needed if we have created userchanges from old style
        if (userChangesFromOldStyle) [self purgeChanges:nil old:YES];
        
    }
    
    else { //otherwise we create from scratch
        
        //does Library/CADictionaries already exist? if not create it
        if (!([defManager fileExistsAtPath:dictionariesDirectory isDirectory:&isDir] && isDir) ) {
            isDir = [defManager createDirectoryAtPath:dictionariesDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
            if (!isDir) { // fatal error - we should bail out!!!
                NSLog(@"fatal error, cannot create CADictionaries");
            }
            else [self setBackupAttributeOfItemAtPath:dictionariesDirectory skipBackup:YES];
        }

        self.theDictionaries = [[NSMutableArray alloc] initWithCapacity:5];
        needsArchiving = YES;
        
        //and set up all the dictionaries, inc userSupplied
        [self setUp];
        
        [self purgeChanges:nil old:NO]; //update userChanges to reflect new dictionaries
        [self archiveDictionaries];
 
    }
    
    return self;
}

- (MyDictionaryObject*) dictionaryWithName:(NSString*)dName safetyNet:(BOOL)sf {
    MyDictionaryObject* theDict = nil;
    int i;
    
    for (i=0; i<[theDictionaries count]; i++) {
        if ([dName isEqualToString:[(MyDictionaryObject*)[theDictionaries objectAtIndex:i] dictName]]) {
            theDict = (MyDictionaryObject*)[theDictionaries objectAtIndex:i];
            break;
        }
    }
    
    if (theDict == nil) {
        if (sf) return (MyDictionaryObject*)[theDictionaries objectAtIndex:0];
        else return nil; //we need the null case to check if dict exists already
    }
     
    return theDict;
}

- (void) setUp {
    int i;
    NSString * path;
    NSError * err;
    NSArray * fArray = [defManager contentsOfDirectoryAtPath:installedDictionariesPath error:&err];
    self.exLibraryDictionaries = [[NSMutableArray alloc] initWithArray:fArray];
    
    //move and initialise installed dicts if necess! from bundle resource to Library (updating dictionary arrays)
    for (i=(int)[exLibraryDictionaries count]-1; i>=0; i--) {
        path = [exLibraryDictionaries objectAtIndex:i];
        if ([path hasSuffix:@"txt"]) continue; //Dictionaries contains the UserAdditions.txt an UserDeletions.txt files
            //we can delete these
        else {
            //evidently path is just the name here?
            [self moveBundledDictionaryToLibrary:[installedDictionariesPath  stringByAppendingPathComponent: path]];
        }
    }
        
    [self updateDictionaryArray];
    
}

- (void)setBackupAttributeOfItemAtPath:(NSString *)path skipBackup:(BOOL)bb
{
    //NSLog(@"setBackupAttr for path %@",path);
    //modify: if a directory, set the attrib for every item!!! if not chop off last component!
    
    NSError *error = nil;
    NSURL *URL;
    BOOL success;
    BOOL isDir = NO, fExists;
    
    fExists = [defManager fileExistsAtPath:path isDirectory:&isDir];
    
    if (!fExists) return;
    
    if ((!isDir)&&([path rangeOfString:@"User"].location == NSNotFound)&&([path rangeOfString:@"CAArchive"].location == NSNotFound)) {
        path = [path stringByDeletingLastPathComponent];
        isDir = YES;
    }
    
    URL = [NSURL fileURLWithPath:path isDirectory:isDir];
    success = [URL setResourceValue: [NSNumber numberWithBool: bb]
                             forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL path], error);
    }
    
}


- (BOOL) moveBundledDictionaryToLibrary:(NSString*)path {
    //note this will not overwrite; so delete first if restoring factory default for a changed or corrupted dictionary
    //this also creates our dictionary objects
    
    NSString * dName, * dstPath;
    BOOL isDir;
    float v, v1;
    
    dName = [path lastPathComponent];
    dstPath = [dictionariesDirectory stringByAppendingPathComponent:dName];
    
   // NSLog(@"will copy %@ to %@", path,dstPath);
    
    //first get the version number
    v = 0.0;    
    NSString * vPath = [path stringByAppendingPathComponent:@"Version"];
    if ([defManager fileExistsAtPath:vPath]) {
        NSData * theData = [defManager contentsAtPath:vPath]; //should be a str, first line 1 floating point value
        NSString *asciiString = [[NSString alloc] initWithData:theData encoding:NSASCIIStringEncoding];
        v = [asciiString floatValue];
    }
    	
    //does the directory exist? if  not copy over the directory
    //change: a cloud backup may have recreated the directory, with only some word files restored
    //Note will have to mark the Version file in case of user change for update also!
    
    isDir = [defManager fileExistsAtPath:dstPath];
    
    if (isDir) { //if already exists, check its version; if <v, remove and copy
        //updating bundled dictionary versions will have to be done differently
        //will need to account for user addition/deletions!!!!!
        v1 = -1.0;
        vPath = [dstPath stringByAppendingPathComponent:@"Version"];
        if ([defManager fileExistsAtPath:vPath]) {
            NSData * theData = [defManager contentsAtPath:vPath]; //should be a str, first line 1 floating point value
            NSString *asciiString = [[NSString alloc] initWithData:theData encoding:NSASCIIStringEncoding];
            v1 = [asciiString floatValue];
        }
        
        //if (YES) {
        //    NSLog(@"force loading of dicts from scratch");
        if (v1 < v) {
            [defManager removeItemAtPath:dstPath error:nil];
            isDir = false;
        }
        
    }
    
    
    if (!isDir) {
        //NSLog(@"copying dictionary %@ version %f to Library",dName,v);
        isDir = [defManager copyItemAtPath:path toPath:dstPath error:nil];
        //if copied, set the Cloud backup attribute for the dir
        [self setBackupAttributeOfItemAtPath:dstPath skipBackup:YES];
    }
    
    if (!isDir) {
        //NSLog(@"error, cannot create %@ directory",dName);
        [viewController oopsAlert:@"Error" message:@"Could not install dictionary; memory problem?"];
        return YES;
    }
    
    //if copied OK , create a dictionary object for this item, and add to theDictionaries
    //but if entry in theDictionaries already exists, update that instead
    MyDictionaryObject * newDictionary;
    
    newDictionary = [self dictionaryWithName:dName safetyNet:NO];
    
    if (newDictionary) {
        newDictionary.dictPath = dstPath;
        newDictionary.sourcePath = path;
        newDictionary.userDeleted = NO;
        newDictionary.version = v;
        newDictionary.userSupplied = NO;
        newDictionary.myDictionaryManager = self;
    }
    else {    
        newDictionary = [[MyDictionaryObject alloc] initWithName:dName path:dstPath version:v userSupplied:NO source:path dictionaryManager:self];
        [theDictionaries addObject:newDictionary];
        newDictionary.entryNumber = (int)[theDictionaries count]-1;
        newDictionary.version = v;
    }
    
    needsArchiving = YES;
    [self updateDictionaryRows];
    
    return NO;

}

- (BOOL) moveUserDictionaryToLibrary:(NSString*)CAdictPath {
    NSString* dName;
    float v;
    
    //here should check if CADictPath is still valid, otherwise put up a dlog
    //NSLog(@"User dlog needed here if removed from userDocs");
    
    //NSLog(@"enter move userDict %@",CAdictPath);
    
    //get components  dictName, version
    int i;

    dName = [CAdictPath lastPathComponent];
    i = (int)[dName length];
    while ([dName characterAtIndex:i-1] != '.') i--;
    dName = [dName substringToIndex:i]; //we have deleted the extension CAdict
    
    //get the version number if any - specify format <name>-<float> or <name>
    while ((i>0) && ([dName characterAtIndex:i-1] != '-')) i--;
    
    if (i==0) v = 0.0;
    else {
        NSString* vString = [dName substringFromIndex:i];
        v = [vString floatValue];
        dName = [dName substringToIndex:i-1];
    }
    
    //NSLog(@"will move %@ version %4.1f",dName,v);
    
    //check if dictionary of this name preexists and not in the removed list!!!
    MyDictionaryObject* oldDict = [self dictionaryWithName:dName safetyNet:NO];
    //if so check version   
    if ((oldDict != nil) && ((oldDict.version >= v) && (!oldDict.userDeleted))) {
       // NSLog(@"move aborted, newer version is installed");
        return YES; //?? safer prob
    }
    
    //otherwise import    
    //NSLog(@"will install %@ from %@", dName,CAdictPath);
    BOOL err = [self doImportDictionary:dName fromPath:[userDocsPath stringByAppendingPathComponent:CAdictPath] version:v];
    
    return err;
    
}

- (void) removeDictionaryFromLibrary: (MyDictionaryObject*)dict{
    
    //put up a dlog ??
    NSError * err;
    
    [defManager removeItemAtPath:dict.dictPath error:&err];
    
    dict.userDeleted = YES;
    dict.dictPath = nil; 
    
    //if confirmed, remove the dictionaryDirectory folder, set the dictPath to nil, mark in theDictionaries (and archive)
    
    needsArchiving = YES;
    [self updateDictionaryRows];
    
}

- (void) updateDictionaryArray{
    //checks for user additions 
    NSString *CAdictPath, *suffix;
    NSArray * paths;
    int i;
    
    //check if any user docs are of type CAdict , if so process
    
    paths = [defManager contentsOfDirectoryAtPath:userDocsPath error:nil];
    if ([paths count]>0) {
        
        //NSLog(@"found %d user docs",[paths count]);
        
        for (i=0; i<[paths count]; i++) {
            CAdictPath = [paths objectAtIndex:i];
            suffix = [CAdictPath pathExtension];
            if ([suffix isEqualToString:@"CAdict"]) {
                [self moveUserDictionaryToLibrary:CAdictPath];
            }
        }
    }
    
    [self updateDictionaryRows];
    
}

- (void) archiveDictionaries {
    NSError * err;
    if ([defManager fileExistsAtPath:archivePath]) {[defManager removeItemAtPath:archivePath error:nil];}
    BOOL result = [NSKeyedArchiver archiveRootObject:theDictionaries toFile:archivePath];
    if (!result) {
        NSLog(@"archiving theDictionaries failed"); //prob don't need any further action
    }
    
    if (![defManager fileExistsAtPath:archivePath]) NSLog(@"archiveDirectory not created");
    else {
         //set the iCloud skip attr        
        [self setBackupAttributeOfItemAtPath:archivePath skipBackup:YES];
    }
    
    //archive userChanges, but only if it is not empty
    //should we verify first - prob yes
    
    if ([userChanges count] >0) {
        result = [NSKeyedArchiver archiveRootObject:userChanges toFile:userChangesArchivePath];
        if (![defManager fileExistsAtPath:userChangesArchivePath]) NSLog(@"userChangesArchive not created");
        else {
            //we do want this backed up, we cannot reconstruct
            [self setBackupAttributeOfItemAtPath:userChangesArchivePath skipBackup:NO];
        }
    }
    else {
        if ([defManager fileExistsAtPath:userChangesArchivePath]) [defManager removeItemAtPath:userChangesArchivePath error:&err];
    }
    needsArchiving = NO;
  
}

- (NSMutableString*) versions{
    //gives version for the currentDictionary
    NSMutableString * str = [[NSMutableString alloc] initWithCapacity:30];
    NSString* entryStr;
    BOOL expNeeded = NO;
    int i;
    for (i=0; i<[theDictionaries count]; i++) {
        MyDictionaryObject* aDict = (MyDictionaryObject*)[theDictionaries objectAtIndex:i];
        if (aDict.userDeleted) continue;
        if (aDict.userModified) {
            entryStr = [aDict.dictName stringByAppendingString:@"*                                       "];
            expNeeded = YES;
        }
        else entryStr = [aDict.dictName stringByAppendingString:@"                                       "];        
        entryStr = [[entryStr substringToIndex:32] stringByAppendingFormat:@"v. %4.1f\n",aDict.version];
        
        
        [str appendString:entryStr];
    }
    
    if (expNeeded) {
        [str appendString:@"\n\n* This dictionary has been modified."];
    }

    return str;
}

- (int) getNextIndexOf:(NSString*)str fromIndex:(int)k toChar:(char)q{
    //get index of the next char which is \t or \n
    //if q = 0, get the rest of the string, but strip last \n
    int j = k+1;
    char c;
    
    if (q == 0) { //get the rest of the string
        j = (int)[str length];
        if ([str characterAtIndex:j-1] == '\n') j--;
    }
    else while (j<[str length]) {
        c = [str characterAtIndex:j];
        if (c == q) break;        
        j++;
    }
    return j;
}

- (NSString*) stripSpacesFrom:(NSString*)str {
    int i,j,n = (int)[str length];
    for (i=0;i<n;i++) {if ([str characterAtIndex:i]!=' ') break;}
    for (j=n-1;j>=0;j--) {if ([str characterAtIndex:j]!=' ') break;}
    return [str substringWithRange:NSMakeRange(i,j-i+1)];
}

- (void) addUserChange:(NSString*)entryStr forDictionary:(NSString*)dictStr
              withDate:(NSString*)   dateStr adding:(BOOL)add {
    //use nil for todays date
    NSDate* theDate;
    NSTimeInterval  inter;
    
    if (dateStr) theDate = [dateFormatter dateFromString:dateStr];
    else theDate = [NSDate date];
    inter = [theDate timeIntervalSinceReferenceDate];       
    
    NSMutableDictionary* changeEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:add], @"addition",
                                        [NSNumber numberWithDouble:inter], @"date",
                                        dictStr, @"dictionary",
                                        entryStr, @"entry",
                                        [NSNumber numberWithBool:NO], @"shared",
                                        nil];
    
    [userChanges addObject:changeEntry];

    [self sendChange:changeEntry];
}

- (void) setupUserChanges {
    BOOL isDir;
    
    NSString* theFile;
    NSError * err;
    
    NSString* contentsStr, * subStr, *dictNameStr, *entryStr, *dateStr;
    NSMutableDictionary* theChange;
    NSDate* theDate;
    NSTimeInterval  inter;
    char c;
    int i,j,ii;
    
    self.userChanges = nil;
    if ([defManager fileExistsAtPath:userChangesArchivePath isDirectory:&isDir]) {
       self.userChanges = [NSKeyedUnarchiver unarchiveObjectWithFile:userChangesArchivePath];
    }
    
    if (self.userChanges == nil) { //not yet archived, or unarchiving failed
        NSMutableArray* anArray= [[NSMutableArray alloc] init];
        self.userChanges = anArray;
    }
    
    //if old version, UserAdditions/Deletions files may still exist
    theFile = [userDocsPath stringByAppendingPathComponent:@"UserAdditions.txt"];
    if ([defManager fileExistsAtPath:theFile isDirectory:&isDir]) {
        contentsStr = [ NSString stringWithContentsOfFile:theFile encoding:NSASCIIStringEncoding error:&err];
        if ([contentsStr length] != 0) {
            //get an entry line
            i = 0;
            while (i<[contentsStr length]) {
                //get a line, from index i
                j = [self getNextIndexOf:contentsStr fromIndex:i toChar:'\n'];
                subStr = [contentsStr substringWithRange:NSMakeRange(i, j-i)];
                                
                c = [subStr characterAtIndex:0]; // is it emptyline?
                if (c == ' ') i = j+1; //go to next line
                
                else if ((c <= '9') && (c >= '0')) { //we have a new line starting with date
                    // dateStr
                    ii = 0;
                    j = [self getNextIndexOf:subStr fromIndex:ii toChar:'\t'];
                    dateStr = [subStr substringWithRange:NSMakeRange(ii, j-ii)];
                    theDate = [dateFormatter dateFromString:dateStr];
                    inter = [theDate timeIntervalSinceReferenceDate];
                    ii = j+1;
                    
                    //dictionary name
                    j = [self getNextIndexOf:subStr fromIndex:ii toChar:'\t'];
                    dictNameStr = [subStr substringWithRange:NSMakeRange(ii, j-ii)];
                    ii = j+1;
                    
                    //entry (word or phrase)
                    j = [self getNextIndexOf:subStr fromIndex:ii toChar:0];
                    entryStr = [subStr substringWithRange:NSMakeRange(ii, j-ii)];
                    entryStr = [self stripSpacesFrom:entryStr];
                    
                    //create a change entry and add it
                    theChange = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool:YES], @"addition",
                                   [NSNumber numberWithDouble:inter], @"date",
                                   dictNameStr, @"dictionary",
                                   entryStr, @"entry",
                                   [NSNumber numberWithBool:NO], @"shared",
                                   nil];
                    
                    [userChanges addObject:theChange];
                    i = i + (int)[subStr length] +1;
                    
                    
                }
                
                else { //we have a line starting with some else; should not happen for add
                    i = i + (int)[subStr length] +1;
                             
                 }
                

            }
        }
        //finally delete the file
        [defManager removeItemAtPath:theFile error:&err];
        
        userChangesFromOldStyle = YES;

    }
    
    //NB this is not right for a deletion of multiple phrases
    //subsequent lines will not have the dictionary name
    //we should continue reading adding to the current line
    
    //perhaps parse for dictname on line starting with digit
    //and prepend to any line starting with non-digit
    theFile = [userDocsPath stringByAppendingPathComponent:@"UserDeletions.txt"];
    if ([defManager fileExistsAtPath:theFile isDirectory:&isDir]) {
        contentsStr = [ NSString stringWithContentsOfFile:theFile encoding:NSASCIIStringEncoding error:&err];
        if ([contentsStr length] != 0) {
            //get an entry line
            i = 0;
            while (i<[contentsStr length]) {
                //get a line, from index i
                j = [self getNextIndexOf:contentsStr fromIndex:i toChar:'\n'];
                subStr = [contentsStr substringWithRange:NSMakeRange(i, j-i)];
                                
                c = [subStr characterAtIndex:0]; // is it emptyline?
                if (c == ' ') i = j+1; //go to next line
                
                else if ((c <= '9') && (c >= '0')) { //we have a new line starting with date
                    // dateStr
                    ii = 0;
                    j = [self getNextIndexOf:subStr fromIndex:ii toChar:'\t'];
                    dateStr = [subStr substringWithRange:NSMakeRange(ii, j-ii)];
                    theDate = [dateFormatter dateFromString:dateStr];
                    inter = [theDate timeIntervalSinceReferenceDate];
                    ii = j+1;
                    
                    //dictionary name
                    j = [self getNextIndexOf:subStr fromIndex:ii toChar:'\t'];
                    dictNameStr = [subStr substringWithRange:NSMakeRange(ii, j-ii)];
                    ii = j+1;
                    
                    //entry (word or phrase)
                    j = [self getNextIndexOf:subStr fromIndex:ii toChar:'\t']; //to next word entry or end of line
                    entryStr = [subStr substringWithRange:NSMakeRange(ii, j-ii)];
                    entryStr = [self stripSpacesFrom:entryStr];
                    
                    //create a change entry and add it
                    theChange = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:NO], @"addition",
                                 [NSNumber numberWithDouble:inter], @"date",
                                 dictNameStr, @"dictionary",
                                 entryStr, @"entry",
                                 [NSNumber numberWithBool:NO], @"shared",
                                 nil];
                    
                    [userChanges addObject:theChange];
                    i = i + j + 1; //start again at next tab or next line
                }
                else { //we have another line of a multiple deletions entry for phrases
                    ii = 0;
                    //entry (word or phrase)
                    j = [self getNextIndexOf:subStr fromIndex:ii toChar:0];
                    entryStr = [subStr substringWithRange:NSMakeRange(ii, j-ii)];
                    entryStr = [self stripSpacesFrom:entryStr];
                    
                    //create a change entry and add it
                    theChange = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:NO], @"addition",
                                 [NSNumber numberWithDouble:inter], @"date",
                                 dictNameStr, @"dictionary",
                                 entryStr, @"entry",
                                 [NSNumber numberWithBool:NO], @"shared",
                                 nil];
                    
                    [userChanges addObject:theChange];
                    i = i + (int)[subStr length] +1;
                }
            }
        }
        //finally delete the file
        [defManager removeItemAtPath:theFile error:&err];
        
        userChangesFromOldStyle = YES;
 
    }
    //cannot be verified because dictionaries not yet in place
}

- (void) sendChange:(NSMutableDictionary*) theChange { //changes for userChanges
    
    if ([MyViewController hasConnectivity] != 0) return;
    
    NSString* filename;
    NSString* contentStr;
    
    filename = [NSString stringWithFormat:@"%@#%f",[viewController uniqueAppID],
                [NSDate timeIntervalSinceReferenceDate]];
    
    if ([[theChange objectForKey:@"addition"] boolValue])
        contentStr = [NSString stringWithFormat:@"+\t%@\t%@",
                                [theChange objectForKey:@"dictionary"],
                                [theChange objectForKey:@"entry"]];
    else
        contentStr = [NSString stringWithFormat:@"-\t%@\t%@",
                                [theChange objectForKey:@"dictionary"],
                                [theChange objectForKey:@"entry"]];
    
    NSString *urlString = @"http://nmsmythe.id.au/CAiOS/upload.php";
    NSMutableURLRequest* request= [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    NSMutableData *postbody = [NSMutableData data];
    [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@.txt\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[contentStr dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:postbody];

    [NSURLConnection
     sendAsynchronousRequest:request
     queue:[[NSOperationQueue alloc] init]
     completionHandler:^(NSURLResponse *response,
                         NSData *data,
                         NSError *error)
     {
         
         if ([data length] >0 && error == nil)
         {
             
             // here set the "shared" keyvalue for theChanges entry
             //NSLog(@"File %@.txt uploaded",filename);
             [theChange setValue:[NSNumber numberWithBool:YES] forKey:@"shared"];
             //[userChanges replaceObjectAtIndex:i withObject:theChange];
             
         }
         else if ([data length] == 0 && error == nil)
         {
             //NSLog(@"Nothing was uploaded.");
         }
         else if (error != nil){
             //NSLog(@"Error = %@", error);
         }
         
     }];

}

- (void) downloadServeDictArrayAsynch {
    //call this asynchronously o launch and when reactivating to upodate serverDictionaryArray

    if ([MyViewController hasConnectivity] != 0){
        viewController.dictionaryUpdateAvailable = NO;
        [viewController.dictionaryAlertButton setHidden:YES];
        return; //don't update; could be an empty array
    }
    
    NSURL  *url = [NSURL URLWithString:[kDictionaryServerSite copy]];
    NSArray * sDictionaryArray;
    NSError* err;
    NSString *urlData = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
    
   MyDictionaryObject* theDict;
    NSMutableDictionary * sDict;
    NSString * serverDictName, *dictName;
    float v1,v2;
    int i,j,D, m = 0;;
    
    if (urlData) {
         sDictionaryArray = [urlData componentsSeparatedByString:@"\n"];
        
        if ([self.serverDictionaryArray count]>0) [self.serverDictionaryArray removeAllObjects];
        D = (int)[sDictionaryArray count];
        
        for (i=0; i<D; i++) {
            serverDictName = [sDictionaryArray objectAtIndex:i];
            if ([serverDictName length]==0) continue;
                        
            j = [self getNextIndexOf:serverDictName fromIndex:0 toChar:'-'];
            dictName = [serverDictName substringToIndex:j];
            
            v1 = [[serverDictName substringFromIndex:j+1] floatValue];
            
            theDict = [self dictionaryWithName:dictName safetyNet:NO];
            if (theDict == nil) { // not installed
                sDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                serverDictName,@"name",
                                [NSNumber numberWithInt:1],@"status", nil];
            }
            else {
                v2 = theDict.version;
                if (v1 == v2) { //installed, same version
                    sDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                             serverDictName,@"name",
                             [NSNumber numberWithInt:2],@"status", nil];
                }
                else {//installed but update available
                    sDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                             serverDictName,@"name",
                             [NSNumber numberWithInt:0],@"status", nil];
                    m++;
                }
            }
            [self.serverDictionaryArray addObject:sDict];
                        
            
        }
        NSArray* sDescriptors = [NSArray arrayWithObjects:
                                 [NSSortDescriptor sortDescriptorWithKey:@"status" ascending:YES],
                                 nil
                                 ];
        [serverDictionaryArray sortUsingDescriptors:sDescriptors];
        
        viewController.dictionaryUpdateAvailable = (m > 0);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->viewController.dictionaryAlertButton setHidden:(m == 0)];
        });
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.NSSoftware.serverArrayUpdated" object:viewController];

    }
    
}

- (int) compareServerVersions:(NSMutableString*) str {
    //See if there are any dictionary updates 
    //pass nil str if only need if an update is available
    
    NSDictionary* theDict;
    int i, k, m = 0;
    if ([MyViewController hasConnectivity] != 0){
        if (str) [str appendFormat:@"Online access to check dictionary versions is not available"];
        return m;
    }
    
    if (self.serverDictionaryArray == nil) {
        if (str) [str appendFormat:@"Online access to check dictionary versions is not available"];
        return m;
    }

    
    int D = (int)[serverDictionaryArray count];
    for (i=0; i<D; i++) {
        theDict = [serverDictionaryArray objectAtIndex:i];
        k = (int)[[theDict objectForKey:@"status"] integerValue];
        if (k == 0) {
                if (str) [str appendFormat:@"An update to %@ is available\n",[theDict objectForKey:@"name"]];
                m++;
            }
        }
    
    if (m==0) if (str) [str appendFormat:@"All installed dictionaries are up to date\n"];
    
    return m;

}

- (NSMutableString*) changes {
    //we now get these from the userChanges array, not from files
    //we could add here a report on sttus of dictionaries
    NSMutableString * str = [[NSMutableString alloc] initWithCapacity:30];
    NSMutableString * additionsStr = [[NSMutableString alloc] initWithCapacity:30];
    NSMutableString * deletionsStr = [[NSMutableString alloc] initWithCapacity:30];
    
    int numAdditions = 0, numDeletions = 0;
    
    int m, i, N = (int)[userChanges count];
    
    if (N == 0) {
        [additionsStr appendString:@"There are no additions recorded for any dictionaries\n\n"];
        [deletionsStr appendString:@"There are no deletions recorded for any dictionaries\n\n"];
        [str appendFormat:@"%@%@",additionsStr,deletionsStr];
        m = [self compareServerVersions:str];
        return str;
    }
    
    NSMutableDictionary* theChange;
    NSTimeInterval tt;
    NSString * dictName, *entry, *dateStr;
    NSDate* theDate;
    for (i=0; i<N; i++) {
        theChange = [userChanges objectAtIndex:i];
        tt = [[theChange objectForKey:@"date"] doubleValue];
        theDate = [NSDate dateWithTimeIntervalSinceReferenceDate:tt];
        dateStr = [dateFormatter stringFromDate:theDate];
        dictName = [theChange objectForKey:@"dictionary"];
        entry = [theChange objectForKey:@"entry"];
        if ([[theChange objectForKey:@"addition"] boolValue] == YES) {
            numAdditions++;
            [additionsStr appendFormat:@"%@   %@: %@\n",dateStr,dictName,entry];
        }
        else {
            numDeletions++;
            [deletionsStr appendFormat:@"%@   %@: %@\n",dateStr,dictName,entry];
        }        
    }
    
    if (numAdditions == 0) {
        [str appendString:@"There are no additions recorded for any dictionaries\n\n"];
    }
    else {
        [str appendFormat:@"Additions: \n%@\n\n",additionsStr];
    }

    if (numDeletions == 0) {
        [str appendString:@"There are no deletions recorded for any dictionaries\n\n"];
    }
    else {
        [str appendFormat:@"Deletions: \n%@\n\n",deletionsStr];
    }
    
    needsArchiving = YES;
    
    //now see if there are any dictionary updates
    m = [self compareServerVersions:str];
    return str;

}

- (const char *) getFormattedDateString {
    NSString * formattedDateString;
    const char * cstr;
    
    //get the current date
    NSDate *date = [NSDate date];
    
    formattedDateString = [dateFormatter stringFromDate:date];    
    
    NSString * dName = [[viewController currentDictionary] dictName];
    //append dictionary name
    
    formattedDateString = [formattedDateString stringByAppendingFormat:@"\t%@\t",dName];
    cstr = [formattedDateString cStringUsingEncoding:NSMacOSRomanStringEncoding];
    
    return cstr;
}

- (void) removeChanges:(NSString *) dictName {
    //removes all changes for the given dict; call after reinstalling a removed dictionary (as opposed to downloading a new one)
    int i, D = (int)[userChanges count];
    MyDictionaryObject* myDict;
    
    myDict = [self dictionaryWithName:dictName safetyNet:NO];
    myDict.userModified = NO;
    
    if (D == 0) return;
    
    NSArray* sDescriptors = [NSArray arrayWithObjects:
                             [NSSortDescriptor sortDescriptorWithKey:@"dictionary" ascending:YES],
                             [NSSortDescriptor sortDescriptorWithKey:@"entry" ascending:YES],
                             nil
                             ];
    [userChanges sortUsingDescriptors:sDescriptors];
    
    NSMutableDictionary* theChange;
    NSString * currDict = @"";
    
    for (i=D;i>0;i--) {
        theChange = [userChanges objectAtIndex:i-1];
        currDict = [theChange objectForKey:@"dictionary"];
        if ([currDict isEqualToString:dictName]) {
            [userChanges removeObject:theChange];
        }
    }
}

- (void) setDictionaryModifiedFlags {
    MyDictionaryObject* myDict;
    int i,j, D = (int)[userChanges count];
    int K = (int)[theDictionaries count];
    NSMutableDictionary* theChange;
    NSString* dictName;
    
    for (j=0; j<K; j++) {
        myDict = [theDictionaries objectAtIndex:j];
        myDict.userModified = NO;
    };
    
    for (i=0;i<D; i++) {
        theChange = [userChanges objectAtIndex:i];
        dictName = [theChange objectForKey:@"dictionary"];
        myDict = [self dictionaryWithName:dictName safetyNet:NO];
        if (myDict) myDict.userModified = YES;
    }

}

- (void) purgeChanges:(NSString *) dictName old:(BOOL) old{
    //set the first entry for a given dict to add/or delete acc as in/out /old/new
    //removes remaining multiple cases of an entry from dictionary dictName, or all if pass nil
    //call nil after converting old style UserAdditions etc (old=YES)
    //call dictName after making a correction (old=YES) and after installing a new version (old=NO)
    
    int i, D = (int)[userChanges count];
    
    if (D == 0) return;

    NSArray* sDescriptors = [NSArray arrayWithObjects:
                             [NSSortDescriptor sortDescriptorWithKey:@"dictionary" ascending:YES],
                             [NSSortDescriptor sortDescriptorWithKey:@"entry" ascending:YES],
                             nil
                             ];
    [userChanges sortUsingDescriptors:sDescriptors];
    
    NSMutableDictionary* theChange;
    NSString * currDict = @"", * currEntry = @"";
    NSString * prevDict = @"", * prevEntry = @"";
    BOOL currAdd, prevAdd;
    MyDictionaryObject* myDict;
    
    for (i=0;i<D;i++) {
        theChange = [userChanges objectAtIndex:i];
        currDict = [theChange objectForKey:@"dictionary"];
        currAdd = [[theChange objectForKey:@"addition"] boolValue];
        if ((dictName)&&(![dictName isEqualToString:currDict])) continue;
        currEntry = [theChange objectForKey:@"entry"];
        
        if ((![currDict isEqualToString:prevDict])||(![currEntry isEqualToString:prevEntry])) { //first occurrence of a correction
            //for old: if entry is in the dict, mark change as an add else as a delete
            //for new: if add and entry is in the dict, trash it; if delete and not, also trash; else leave it
            myDict = [self dictionaryWithName:currDict safetyNet:NO];
            if (!myDict)  continue; //change is for a missing dictionary!!! should not happen
            
            int retVal = [myDict dictionaryContainsEntry:currEntry adding:NO deleting:NO];
            
            if (old) {
                if (retVal == 1) [theChange setObject:[NSNumber numberWithBool:YES] forKey:@"addition"];
                else if (retVal == 0) [theChange setObject:[NSNumber numberWithBool:NO] forKey:@"addition"];
            }
            else { //for newly installed dictionary
                
                if (currAdd) {
                    if (retVal == 1) [theChange setObject:@"Trash" forKey:@"dictionary"]; //already in new dict so trash change
                    else //add it to the new dict
                        [myDict dictionaryContainsEntry:currEntry adding:YES deleting:NO];
                }
                else {
                    if (retVal == 0) [theChange setObject:@"Trash" forKey:@"dictionary"]; // already deleted from new dict
                    else //delete from new dict
                        [myDict dictionaryContainsEntry:currEntry adding:NO deleting:YES];
                    
                }
            }
            
            prevDict = currDict;
            prevEntry = currEntry;
            prevAdd = currAdd;
        }
        
        else  { //we have same dictionary and same entry as previous: //just mark as trashable 
            [theChange setObject:@"Trash" forKey:@"dictionary"];
            
            prevDict = currDict;
            prevEntry = currEntry;
            prevAdd = currAdd;
        }
        
    }
    
    for (i=D;i>0;i--) {
        theChange = [userChanges objectAtIndex:i-1];
        currDict = [theChange objectForKey:@"dictionary"];
        if ([currDict isEqualToString:@"Trash"]) [userChanges removeObject:theChange];
    }
    
    [self setDictionaryModifiedFlags];
}

#pragma mark -
#pragma mark import and unpack CAdict

- (BOOL) doImportDictionary:(NSString *) dictName fromPath:(NSString *) CAdictPath version:(float)v 
{   int length=0,count=0,i;
    NSString * fileName, *dictPath;
    char ch, initialChar=0,r;
    char buffer[8],data[5];
    FILE * filePtr = nil, *dictPtr = nil;
    BOOL done,wordsDone;
    int mode;
    
    
    NS_DURING
    
    //NSLog(@"import CADictPath %@",CAdictPath);
    
    dictPtr=fopen([CAdictPath UTF8String],"r");//why UTF8?? because filenames always use UTF8 to ensure chars like ƒ work
    if (!dictPtr) [[NSException exceptionWithName:@"Error" reason:@"Cannot read user .CAdict file" userInfo:nil] raise];
    
//CFAbsoluteTime TT = CFAbsoluteTimeGetCurrent();
    
    //NSLog(@"started at %f",TT);
    
    //create a folder named dictName in the Library
    //this should be a temp folder so it can be deleted if error, and may overwrite existing of later version
    
    dictPath = [dictionariesDirectory stringByAppendingPathComponent:@"Temp"];
    
    //NSLog(@"will write to %@", dictPath);
    
    [defManager createDirectoryAtPath:dictPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    ch=-1; done=NO;
    //headers
    while ((!feof(dictPtr))&&(ch!=0)) {ch=getc(dictPtr);} //skip 2 cstrings
    ch=-1;
    while ((!feof(dictPtr))&&(ch!=0)) {ch=getc(dictPtr);} 
        
    mode=2; wordsDone=NO; filePtr=nil;
    while ((!feof(dictPtr))&&(!done)) {
        if (mode==2) { //start of a lengthpart
            length=getc(dictPtr); //NB length will only be valid if this mode has been encountered  
            if (wordsDone) fileName=[dictPath stringByAppendingPathComponent:[NSString stringWithFormat:@"phrases%d.txt",length]];
            else fileName=[dictPath stringByAppendingPathComponent:[NSString stringWithFormat:@"words%d.txt",length]];
            filePtr=fopen([fileName UTF8String],"w");
            if (!filePtr) {
                //NSLog(@"bad filePtr for length = %d, file %@ ",length, fileName);
                [[NSException exceptionWithName:@"Error" reason:@"Cannot write to word list" userInfo:nil] raise];
            }
            count=0; //number of characters so far written of each word item 
            mode=3;}
        else if (mode==1) { //end of lengthpart
            if (filePtr) fclose(filePtr); filePtr=nil; 
            mode=2;}
        else if (mode==3) { //start a new letter
            ch=getc(dictPtr);
            if (ch==0) {if (filePtr) fclose(filePtr); filePtr=nil; done=YES; } 
            else if (ch==1) {mode=1; }//end of length part marker
            else if (ch==2) {wordsDone=YES; mode=1;  } //end of first word list
            else if ((ch<'A')||(ch>'Z')) {
                [[NSException exceptionWithName:@"Error" reason:@"Bad character in import file" userInfo:nil] raise];}
            else {initialChar=ch; count=0; mode=5;}
        }
        else if (mode==5) { //a data block, or a marker
            data[0]=getc(dictPtr); 
            if (data[0]==0) {if (filePtr) fclose(filePtr);  filePtr=nil; done=YES; } 
            else if (data[0]==1) {mode=1; }//end of length part marker
            else if (data[0]==2) {wordsDone=YES; mode=1; } //end of first word list
            else if (data[0]==3) {mode=3;} //end of letter sequence within a length file
            else { // read and process next 4 bytes
                for (i=1;i<5;i++) {data[i]=getc(dictPtr); }
                buffer[0]=(data[0]>>3)&0x1F; r=data[0]&0x07;  //nb >> will propagate -1 flag
                buffer[1]=(r<<2)|((data[1]>>6)&0x03); r=data[1]&0x3F;
                buffer[2]=(r>>1); r=r&0x01;
                buffer[3]=(r<<4)|((data[2]>>4)&0x0F); r=data[2]&0x0F; 
                buffer[4]=(r<<1)|((data[3]>>7)&0x01); r=data[3]&0x7F;
                buffer[5]=(r>>2); r=r&0x03;
                buffer[6]=(r<<3)|((data[4]>>5)&0x07); 
                buffer[7]=data[4]&0x1F;
                
                for (i=0;i<8;i++) {                    
                    if (count==length) {putc('\t',filePtr); count=0;}
                    if (buffer[i]!=4) {                        
                        if (count==0) {putc(initialChar,filePtr); count++;}
                        if (count<length) { if (buffer[i]==31) putc(' ',filePtr); else putc(60+buffer[i],filePtr); count++;}
                        else {putc('\t',filePtr); count=0;}
                    }
                }
            }
        }
    }
    
    fclose(dictPtr); dictPtr = nil;
    
    //everything OK so remove any old version and change name
    NSString * destPath =  [dictionariesDirectory stringByAppendingPathComponent:dictName];
    BOOL isDir;
    if ([defManager fileExistsAtPath:destPath isDirectory:&isDir] && isDir) {
        [defManager removeItemAtPath:destPath error:nil];
    }
    
    [defManager moveItemAtPath:dictPath toPath:destPath error:nil];
    
    //must also create the version file ...
    NSString * vFilepath = [destPath stringByAppendingPathComponent:@"Version"];
    NSString * vString = [NSString stringWithFormat:@"%f\n%s\n",v,[self getFormattedDateString]];
    const char* vData = [vString cStringUsingEncoding:NSASCIIStringEncoding];
    [defManager createFileAtPath:vFilepath contents:[NSData dataWithBytes:vData length:[vString length]] attributes:nil]; //check 
    
    //TT = CFAbsoluteTimeGetCurrent() - TT;
    //NSLog(@"import time %f seconds",TT);
    //[[viewController resultsField] setText:[NSString stringWithFormat:@"import time %f seconds",TT]];
    
    //and create dictionary, and add to theDictionaries, unless entry already exists
    MyDictionaryObject * newDictionary;
    newDictionary = [self dictionaryWithName:dictName safetyNet:NO];
    
    if (newDictionary) {
        newDictionary.dictPath = destPath;
        newDictionary.sourcePath = CAdictPath;
        newDictionary.userDeleted = NO;
        newDictionary.version = v;
        newDictionary.userSupplied = YES;
        newDictionary.myDictionaryManager = self;
    }
    else {
        newDictionary = [[MyDictionaryObject alloc] initWithName:dictName path:destPath version:v userSupplied:YES source:CAdictPath dictionaryManager:self];
        [theDictionaries addObject:newDictionary];
        newDictionary.entryNumber = (int)[theDictionaries count]-1;
        newDictionary.version = v;        
    }
    
    //uncomment the following line to log the location of the processed word/phrase files
    //when done in a simulator, use this method to convert XCodes input dictionary files from the CA ouput .CAdict file
    
    //NSLog(@"imported dictionary %@ saved to %@",newDictionary.dictName,newDictionary.dictPath);
    
    needsArchiving = YES;
    [self updateDictionaryRows];
    
    return NO;
    
    NS_HANDLER {
        if (dictPtr) fclose(dictPtr);
        if (filePtr) fclose(filePtr); //crash here???
        
        [viewController oopsAlert:@"Error" message:@"Custom dictionary in the Document folder may be corrupted - cannot install!"];
        
        if ([defManager fileExistsAtPath:dictPath]) [defManager removeItemAtPath:dictPath error:nil];
        
        [defManager moveItemAtPath:CAdictPath toPath:[CAdictPath stringByAppendingString:@"bad"] error:nil]; //this doesnt seem to work - could be a permissions problem?
        return YES;
    }
    NS_ENDHANDLER
    
}

- (int) numberOfInstalledDictionaries {
    int i, numInstalled = 0;
    for (i=0; i<[theDictionaries count]; i++) {
        if (![(MyDictionaryObject*)[theDictionaries objectAtIndex:i] userDeleted])
            numInstalled++;
    }
    return numInstalled;  
}

- (int) numberOfRemovedDictionaries {
    int i, numRemoved = 0;
    for (i=0; i<[theDictionaries count]; i++) {
        if ([(MyDictionaryObject*)[theDictionaries objectAtIndex:i] userDeleted])
            numRemoved++;
    }
    return numRemoved;  
}

- (void) updateDictionaryRows {
    int i, j = -1, k = -1;
    int n = (int)[theDictionaries count];
    NSArray* sDescriptors = [NSArray arrayWithObjects:
                             [NSSortDescriptor sortDescriptorWithKey:@"dictName" ascending:YES],
                             nil
                             ];
    [theDictionaries sortUsingDescriptors:sDescriptors];
    MyDictionaryObject* theDict;
    for (i=0; i<n; i++) {
        theDict = [theDictionaries objectAtIndex:i];
        needsArchiving = needsArchiving || (theDict.entryNumber != i);
        theDict.entryNumber = i;
        if (theDict.userDeleted) {
            j++;
            needsArchiving = needsArchiving || (theDict.removedRowNumber != j);
            theDict.removedRowNumber = j;
            theDict.installedRowNumber = -1;
        }
        else {
            k++;
            needsArchiving = needsArchiving || (theDict.installedRowNumber != k);
            theDict.installedRowNumber = k;
            theDict.removedRowNumber = -1;
        }
        //NSLog(@"update dict %@, entry %d, installedRow %d, removed Row",theDict.dictName,theDict.installedRowNumber, theDict.removedRowNumber);
    }
}

#pragma mark -
#pragma mark Download&Install

- (void) downLoadAndInstall:(NSString*)dName {
    //get the version number if any - specify format <name>-<float> or <name>
    //NSLog(@"dname *%@*",dName);
    int i = (int)[dName length];
    float v;
    while ((i>0) && ([dName characterAtIndex:i-1] != '-')) i--;
    NSString* vString = [dName substringFromIndex:i];
    v = [vString floatValue];
    NSString* dNameStripped = [dName substringToIndex:i-1];
    
    //must get the unversioned name, and check if already exists
    MyDictionaryObject*  selDictionary = [self dictionaryWithName:dNameStripped safetyNet:NO];
    
    if (selDictionary && !selDictionary.userDeleted) {
        NSString * message = [NSString stringWithFormat:
                              @"A dictionary with name %@, version %4.1f already exists; replace it?",selDictionary.dictName,selDictionary.version];
        
        self.downloadAlert = [[UIAlertView alloc] initWithTitle:dName message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Replace", nil];
        downloadAlert.tag = 17; //in case we have others!!!
        [downloadAlert show]; //???alert shows, but cancel always crashes, doesn't get to delegate method!!!!, Replace may NB we seem to be allowing replace currentDict
        return;
    }
    else [self downLoadAndInstall2:dName];
    
}

- (void) downLoadAndInstall2:(NSString*) dName {
    
    //NSLog(@"dName *%@*",dName);
    NSString* dFullName = [dName stringByAppendingString:@".CAdict"];
    //quotes dont seem to work - can we replace spaces with %20
    NSString* dFullNameFixed = [dFullName stringByReplacingOccurrencesOfString:@" " withString:@"\%20"];
    
    //NSLog(@"dFullNameFixed *%@*",dFullNameFixed);
    
    //we need to stripped version and if already exists!
    int i = (int)[dName length];
    float v;
    while ((i>0) && ([dName characterAtIndex:i-1] != '-')) i--;
    NSString* vString = [dName substringFromIndex:i];
    v = [vString floatValue];
    NSString* dNameStripped = [dName substringToIndex:i-1];
    
     //NSLog(@"dNameStripped *%@*",dNameStripped);
    
    //download from CAiOS/Dictionaries to the user docs//and install!
    
    //NSLog(@"dictStringURL *%@*",dictStringURL);
    
    //NSLog(@"full path *%@*",[[dictStringURL copy]stringByAppendingPathComponent:dFullNameFixed]);
        
    NSURL  *url = [NSURL URLWithString:[[dictStringURL copy]stringByAppendingPathComponent:dFullNameFixed]];//ARC requires copy here
    
    //NSLog(@"url *%@*",url);
    
    BOOL succeeded;
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    
    if (urlData) {
        NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString  *documentsDirectory = [paths objectAtIndex:0];  
        
        NSString  *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory,dFullName];
        succeeded = [urlData writeToFile:filePath atomically:YES];
        
        if (!succeeded) {
            [viewController oopsAlert:@"Error" message:@"The new dictionary could not be saved!"];
            [viewController.numLettersField setText:@""];
            [viewController.patternField setText:@""];
            [viewController.anagramField setText:@""];
            [viewController.resultsField setText:@""];
            [viewController.numResultsLabel setText:@""];

        }
        else {
            //if (selDictionary && selDictionary.userDeleted) {
            //    NSLog(@"must remove the existing dictionary");// but can use current entry in theDictionaries even if userDeleted
            //}//remove it!!
            //check - does moveUserDictionary already do this - but if so override any version test YEs
            
            //import and set
            
            [self doImportDictionary:dNameStripped fromPath:[documentsDirectory stringByAppendingPathComponent:dFullName] version:v];
            [self updateDictionaryRows];
            [viewController setDictionary:dNameStripped];
            
            //also update serverDictionaryArray
            dispatch_async(viewController.backgroundQueue, ^(void) {
                [self downloadServeDictArrayAsynch];
            });
            
            [self purgeChanges:dNameStripped old:NO];
            
            [viewController.resultsField setText:[NSString stringWithFormat:@"Dictionary %@ installed",dName]];
            [viewController.patternField setText:@""];
            [viewController.anagramField setText:@""];
            [viewController.numLettersField setText:@""];
            [viewController.numResultsLabel setText:@""];

        }
    }
    
    else {
        [viewController.numLettersField setText:@""];
        [viewController.patternField setText:@""];
        [viewController.anagramField setText:@""];
        [viewController.resultsField setText:@""];
        [viewController.numResultsLabel setText:@""];
        
        [viewController oopsAlert:@"Error" message:@"An error occurred while downloading!"];

        return;
    }    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.downloadAlert = nil;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {    
    if (alertView.tag == 17) {
        if (buttonIndex == 0) {
            [viewController dismissSelectionTable];
            return;
        } 
        else {
            //and bring up a processing message
            [viewController.resultsField setTextColor:[UIColor blueColor]];
            [viewController.resultsField setText:@"Downloading and processing dictionary ... please wait"];

            [self performSelector:@selector(downLoadAndInstall2:)  withObject:alertView.title afterDelay:0.1];
            //to allow alert to dismiss
        }
    }
}

@end
