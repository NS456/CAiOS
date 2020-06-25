//
//  MyDictionaryObject.m
//  CAiOS
//
//  Created by Neville Smythe on 8/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyViewController.h"
#import "MyDictionaryObject.h"
#import "DictionaryManager.h"
#import "AppDelegate_iPhone.h"

@interface MyDictionaryObject (PrivateUtilities)

- (void) phraseSearchWithResFile:(FILE *) resFilePtr numResults:(int) numHits;
	int  findChars(char * myChars, int N, NSString * targetString, BOOL flag,int startPoint);

@end


@implementation MyDictionaryObject

@synthesize version;
@synthesize dictName;
@synthesize dictPath, sourcePath;
@synthesize userSupplied, userDeleted, userModified;
@synthesize entryNumber, installedRowNumber, removedRowNumber;

@synthesize numLetters;
@synthesize pattern;
@synthesize anagram;
@synthesize numResults;
@synthesize searchResults;
@synthesize theNumWords;
@synthesize theLength;
@synthesize theFullLength;
@synthesize plusFlag;
@synthesize errFlag;
@synthesize errString;
@synthesize myDictionaryManager;

- (id)initWithName: (NSString*)theName path:(NSString*) path version: (float) v  userSupplied:(BOOL)user source:(NSString*) source dictionaryManager:(DictionaryManager*)dM
{		
    self = [super init];
    if (self) {
        self.dictName = theName;
        self.dictPath = path;
        self.sourcePath = source;
        self.version = v;
        self.userSupplied = user;
        self.userDeleted = NO;
        self.userModified = NO;
        self.myDictionaryManager = dM; //nb if the dictionary is inited by unarching, this is not set!
        
        self.entryNumber = 0; //this must be updated when installed
        
        self.numLetters = @"";
		self.pattern = @"";
		self.anagram = @"";
		self.errString = @"";
		self.searchResults = [[NSMutableString alloc] initWithString:@""];

        int i;
        for (i=0;i<MAXNUMWORDS; i++) {theWordLengths[i] = 0;}
		self.theNumWords = 0;
		self.theFullLength = 0;
		self.plusFlag = NO;
		searchFlag = NO;
    }

    return self;
}

- (void) setupMyDictionaryManager {
    if (myDictionaryManager == nil) {
        AppDelegate_iPhone* myDelegate = [[UIApplication sharedApplication] delegate];
        self.myDictionaryManager = [(MyViewController*)[myDelegate myViewController] myDictionaryManager];
    }

}

/*

- (void) setupDictionary: (NSString*)newDictionaryName { //what is this about??? superceded by setting default diction...
	NSString * aName;
	if (newDictionaryName == nil) {		
		aName = [[NSString alloc] initWithString:@"English"]; //default!!!
		self.dictName = aName;
	}
	else {
		self.dictName = newDictionaryName;
		//[newDictionaryName release]; //?? check how the string is formed from list
	}
	//self.dictPath = [dictionariesDirectory stringByAppendingPathComponent:dictName];
}
*/

- (void) setTheWordLengths: (int) i : (int) j
{
	if (i<MAXNUMWORDS) {theWordLengths[i] = j;}
}

- (int) theWordLengths: (int) i
{	return theWordLengths[i];
}

- (void) doSearch {
	
	NSUInteger i,k;
    char * fName;
	char ch;
	char myPattern[MAXPATLENGTH];
	int anagramLetters[29], lcanagramLetters[29]; //num occurrences A-Z, - @ *, and a working copy
    char testWord[MAXWORDLENGTH];
    int numAnagram;
    int firstPatternTest,firstAnagramTest;
    FILE * filePtr;
    int numHits,lengthPlus, defer;
    BOOL hit, firstPatternTestFound,firstAnagramTestFound;
	
	if (theLength==0) {
		numHits=0;
		errFlag = YES;
		self.errString = @"Attempt to search for 0 length - should not happen!";
		self.searchResults=[NSMutableString stringWithCapacity:32]; //this causes crash!!!
		return;
	}//for safety
	
	errFlag = NO;
	self.errString = @"";
	
	numResults = 0;
	self.searchResults = [NSMutableString stringWithCapacity:15000];
	
	if (theNumWords>1) {[self phraseSearchWithResFile:nil numResults:0]; return;}
	   	
	lengthPlus=theLength+1;
    firstPatternTest=0;
	firstPatternTestFound=NO;
	firstAnagramTestFound=NO;
	
	//wildPattern is number of wildcards, firstPatternTest first char needing testing, firstPatternTestFound yes if needs test	
	for (i=0; i<[pattern length]; i++) {
		ch = [pattern characterAtIndex:i];
		myPattern[i] = ch;
		if (ch==45) {if (!firstPatternTestFound) firstPatternTest++;}
        else if ((ch==64)||(ch==36)) {firstPatternTestFound=YES;}
        else firstPatternTestFound=YES;
	}
    
    for (i = (int)[pattern length]; i<theLength; i++) {
		myPattern[i] = '-'; 
		if (!firstPatternTestFound) firstPatternTest++;
	} //wildPattern is number of wildcards, firstPatternTest first char needing testing, firstPatternTestFound yes if needs test

	numAnagram=0;
    firstAnagramTest=0;	
	for (k=0; k<29;k++) anagramLetters[k]=0;
	for (i=0;i<[anagram length];i++) {
		ch = [anagram characterAtIndex:i];
		if (ch=='-') {
			anagramLetters[26]++;
			if (!firstAnagramTestFound) firstAnagramTest++;
		}
		else if (ch=='@') {
			anagramLetters[27]++;
			firstAnagramTestFound=YES;
		}
		else if (ch=='$') {
			anagramLetters[28]++;
			firstAnagramTestFound=YES;
		}
		else if ((ch>='A') && (ch<='Z')) {
			anagramLetters[ch-'A']++;
			firstAnagramTestFound=YES;
		}
		else {//should not happen - for robustness 
			errFlag = YES;
			self.errString = @"Illegal character encountered in Anagram";
			return;
		}
	}
	if ([anagram length]<theLength) {
		anagramLetters[26] = anagramLetters[26] + theLength - (int)[anagram length];
		if (!firstAnagramTestFound) firstAnagramTest = theLength;
		//wildAnagram = anagramLetters[26] + theLength - [anagram length]; 
	}
		
	fName = (char *)[[dictPath stringByAppendingPathComponent:[NSString stringWithFormat:@"words%d.txt",theLength]] UTF8String];    
    filePtr = fopen(fName,"r");
    if (filePtr==NULL) { 
		errFlag = YES;
		self.errString = [NSString stringWithFormat:@"Dictionary %@ or file words%d.txt is missing or corrupted!",dictName,theLength];
		return;
	}
    else {		
		numHits = 0;
		defer = 0; 
		//get testword (testing for eof) need a signal catch!
            while (YES) {
                if (fread(testWord,1,lengthPlus,filePtr)!=lengthPlus) break;
                
				//test it --- first the Pattern
                hit = NO;
				if (!firstPatternTestFound) hit=YES;
                else for (i=firstPatternTest;i<theLength;i++) {
                    ch=testWord[i];
                    hit=(ch==myPattern[i]);
                    if (!hit) {
						hit=(myPattern[i]==45);
						if (!hit) {
							hit=(myPattern[i]==64) && ((ch=='A')||(ch=='E')||(ch=='I')||(ch=='O')||(ch=='U')||(ch=='Y'));
							hit=(hit) || ((myPattern[i]==36)&& ((ch!='A')&&(ch!='E')&&(ch!='I')&&(ch!='O')&&(ch!='U')));
						};
					};
                    if (!hit) break;
				};
				
                //if (hit && (firstAnagramTest<theAnagramLength) && (wildAnagram<theLength)) { 
					//now test anagram
				if (hit && firstAnagramTestFound) {
                   
                    for (k=0;k<29;k++) lcanagramLetters[k]=anagramLetters[k];
					defer = 0;
                    for (i=0;i<theLength;i++) {
                        hit=NO;
                        ch=testWord[i];
						if ((ch>='A') && (ch<='Z') && (lcanagramLetters[ch-65]>0)) {
							hit = YES;
							lcanagramLetters[ch-65]--;
						}
						if (!hit) {//check for vowel matching @
							if (((ch=='A')||(ch=='E')||(ch=='I')||(ch=='O')||(ch=='U')) && (lcanagramLetters[27]>0)) {
								hit = YES;
								lcanagramLetters[27]--;
							}
						}
						if (!hit) {//check for consonant matching $
							if (((ch!='A')&&(ch!='E')&&(ch!='I')&&(ch!='O')&&(ch!='U')) && (lcanagramLetters[28]>0)) {
								hit = YES;
								lcanagramLetters[28]--;
							}	
						}
						if (!hit && (ch=='Y') && (lcanagramLetters[26]+lcanagramLetters[27]+lcanagramLetters[28]>0)) {
							defer++;
							hit = YES;
						}
						else if ((!hit) && (lcanagramLetters[26]>0)) {//check for anything else matching -
							hit = YES;
							lcanagramLetters[26]--;
						}
					
					
                        if (!hit) break;
					}
					if (hit && (defer>0)) {
						hit  = (lcanagramLetters[26]+lcanagramLetters[27]+lcanagramLetters[28] >= defer);
					}
				};
				
                //if a hit append to results
                if (hit) { 
                    if (numHits<MAXHITDISPLAY) {
						testWord[theLength]=0;
						[searchResults appendFormat:@"%s    ",testWord]; //separate with 4 spaces, tab not available
						
					}
                    numHits++;
				};
			} 
			
            fclose(filePtr);
		
			[searchResults appendFormat:@"\n"];
            			
            if (plusFlag) {[self phraseSearchWithResFile:nil numResults:numHits]; return;}
            
			if (numHits>MAXHITDISPLAY) [searchResults appendFormat:@"\n…and %d more words", numHits-MAXHITDISPLAY];
			numResults = numHits;

    }
	
}

- (void) phraseSearchWithResFile:(FILE *) resFilePtr numResults:(int) numHits {
	int i,j,k,q,maxLength,minLength,patLength;
	int numPhraseHits;
	char * fName;
	char ch;
	char myPattern[MAXPATLENGTH];
	int anagramLetters[29], lcanagramLetters[29]; //num occurrences A-Z, - @ *, and a working copy
	char testWord[MAXWORDLENGTH];
	int numAnagram;
	int firstPatternTest,firstAnagramTest;
	FILE * filePtr;
	int lengthPlus, defer;
	BOOL hit, firstPatternTestFound,firstAnagramTestFound;
	
	if (theLength==0) {
		numHits=0;
		self.searchResults=[NSMutableString stringWithCapacity:32];
		return;
	}//for safety
    
    //fix pattern and anagram to fill out
    //do this in modify to conform surely!!!
	
	numPhraseHits = 0;
	
	patLength=theFullLength;
	lengthPlus=patLength+1;
	firstPatternTest=0;
	firstPatternTestFound=NO;
	firstAnagramTestFound=NO;
    

	//firstPatternTest first char needing testing, firstPatternTestFound yes if needs test	
	for (i=0; i<[pattern length]; i++) {
		ch = [pattern characterAtIndex:i];
		if (ch==',') myPattern[i] = ' '; else myPattern[i] = ch; //replace iOS , with space as used in dictionaries
		if (ch==45) {if (!firstPatternTestFound) firstPatternTest++;}
		else if ((ch==64)||(ch==36)) {firstPatternTestFound=YES;}
		else firstPatternTestFound=YES;
	}
	for (i=(int)[pattern length]; i<patLength; i++) {
		myPattern[i] = '-'; 
		if (!firstPatternTestFound) firstPatternTest++;
	} //firstPatternTest first char needing testing, firstPatternTestFound yes if needs test

	numAnagram=0;
	firstAnagramTest=0;	
	for (k=0; k<29;k++) anagramLetters[k]=0;
	for (i=0;i<[anagram length];i++) {
		ch = [anagram characterAtIndex:i];
		if (ch=='-') {
			anagramLetters[26]++;
			if (!firstAnagramTestFound) firstAnagramTest++;
		}
		else if (ch=='@') {
			anagramLetters[27]++;
			firstAnagramTestFound=YES;
		}
		else if (ch=='$') {
			anagramLetters[28]++;
			firstAnagramTestFound=YES;
		}
		else if ((ch>='A') && (ch<='Z')) {
			anagramLetters[ch-'A']++;
			firstAnagramTestFound=YES;
		}
		else {//should not happen - for robustness 
			errFlag = YES;
			self.errString = @"Illegal character encountered in Anagram";
			return;
		}
	}
	if ([anagram length]<theLength) {
		anagramLetters[26] = anagramLetters[26] + theLength - (int)[anagram length];
		if (!firstAnagramTestFound) firstAnagramTest = patLength;
	}
	
	if (plusFlag) { 
        minLength=patLength; 
        maxLength=2*patLength+1;
        if (maxLength>MAXPHRASELENGTH) maxLength=MAXPHRASELENGTH;
    }
    else { minLength=patLength; maxLength=lengthPlus;}
    if (minLength<3) minLength=3;
    	
	//open file for results
	defer = 0; //'Y' must be tested last, will match remaining wild cards
	
	for (q=minLength; q<maxLength; q++) { //search in phrases of length  q      
		fName=(char *)[[dictPath stringByAppendingPathComponent:
						[NSString stringWithFormat:@"phrases%d.txt",q]] UTF8String];    
		filePtr=fopen(fName,"r");
		if (filePtr==NULL) { 
			errFlag = YES;
			self.errString = [NSString stringWithFormat:@"Dictionary %@ or file phrasess%d.txt is missing or corrupted!",dictPath,q];
			return;
			}
		else {  
			//get testword (testing for eof) need a signal catch?
			while (YES) {
				if (fread(testWord,1,q+1,filePtr)!=q+1) break;
				//test it --- first the Pattern
				j=-1;
				for (i=0;i<patLength;i++) {
					j++; ch=testWord[j];
					if (plusFlag && (ch==32) && (myPattern[i]!=32)) {j++;  ch=testWord[j];}
					hit=(ch==myPattern[i]);
					if ((!hit) && (ch!=32)) {
						hit=(myPattern[i]==45);
						if (!hit) {
							hit=(myPattern[i]==64) && ((ch=='A') || (ch=='E') ||(ch=='I') || (ch=='O') || (ch=='U') || (ch=='Y'));
							hit=(hit) || ((myPattern[i]==36)&& ((ch!='A') &&(ch!='E') && (ch!='I') && (ch!='O') && (ch!='U')));
						};
					};
					if (!hit) break;
				};
				//j should run out at same time as i!
				hit=(hit)&&(j==q-1);
				
				if (hit && firstAnagramTestFound) {
					
                    for (k=0;k<29;k++) lcanagramLetters[k]=anagramLetters[k];
					defer = 0;
					j=-1; //same as test for words but skip spaces in testword
                    for (i=0;i<theLength;i++) {
                        hit=NO;
						j++; ch=testWord[j];
						if (ch==32) {j++;  ch=testWord[j];}
						if ((ch>='A') && (ch<='Z') && (lcanagramLetters[ch-65]>0)) {
							hit = YES;
							lcanagramLetters[ch-65]--;
						}
						if (!hit) {//check for vowel matching @
							if (((ch=='A')||(ch=='E')||(ch=='I')||(ch=='O')||(ch=='U')) && (lcanagramLetters[27]>0)) {
								hit = YES;
								lcanagramLetters[27]--;
							}
						}
						if (!hit) {//check for consonant matching $
							if (((ch!='A')&&(ch!='E')&&(ch!='I')&&(ch!='O')&&(ch!='U')) && (lcanagramLetters[28]>0)) {
								hit = YES;
								lcanagramLetters[28]--;
							}	
						}
						if (!hit && (ch=='Y') && (lcanagramLetters[26]+lcanagramLetters[27]+lcanagramLetters[28]>0)) {
							defer++;
							hit = YES;
						}
						else if ((!hit) && (lcanagramLetters[26]>0)) {//check for anything else matching -
							hit = YES;
							lcanagramLetters[26]--;
						}
						
						
                        if (!hit) break;
					}
					if (hit && (defer>0)) {
						hit  = (lcanagramLetters[26]+lcanagramLetters[27]+lcanagramLetters[28] >= defer);
					}
				};
				if (hit) { 
					if (numPhraseHits<MAXHITDISPLAY) {
						testWord[q]=0;
						[searchResults appendFormat:@"%s\n",testWord];
					}
					numPhraseHits++;
				};
			} 
			
			fclose(filePtr);
		}
	}
    //fclose(resFilePtr);
	
	if (numHits>MAXHITDISPLAY) [searchResults appendFormat:@"\n…and %d more words", numHits-MAXHITDISPLAY];
	if (numPhraseHits>MAXHITDISPLAY) [searchResults appendFormat:@"\n…and %d more phrases", numPhraseHits-MAXHITDISPLAY];
	
	numResults = numHits + numPhraseHits;			
}

- (int) dictionaryContainsEntry:(NSString*)entry adding:(BOOL)add deleting:(BOOL) del {
    //get the numLetters from entry and load the approp file; call findChars
    //we must use pattern for add; must be reset to current value
    //return -1 if error, 0 for false, 1 for true
    BOOL isPhrase = NO;
    int retVal;
    char ch;
    char myWord[MAXPATLENGTH]; // savePattern[MAXPATLENGTH]; //MAXPATTERNLENGTH???
    int i, insertLoc, L = (int)[entry length];
    
    [self setupMyDictionaryManager]; //in case first use after unarchiving
    
    for (i=0; i<L; i++) {
        ch = [entry characterAtIndex:i];
        myWord[i] = ch; //for searching in dict file, spaces are used in phrases
        if (ch == ' ') isPhrase = YES;
    }
    myWord[L] = 0;
    
    NSString * fileName;
    if (isPhrase) fileName = [self.dictPath stringByAppendingPathComponent:[NSString stringWithFormat:@"phrases%d.txt",L]];
    else fileName = [self.dictPath stringByAppendingPathComponent:[NSString stringWithFormat:@"words%d.txt",L]];
    
    //read the existing file as string
    int wLength=[[[[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:NULL] objectForKey:NSFileSize] intValue];
    
    //make a new mutable stringfor file.txt of capacity old+L+2
    NSMutableString * dStr=[NSMutableString  stringWithCapacity:wLength+L+2]; //for add we need L more chars
    if (!dStr) { //we have a problem - what to return??
        return -1;
    }
    
    NS_DURING
    //read in existing wordsN.txt
    [dStr appendString:[NSString stringWithContentsOfFile:fileName encoding:NSMacOSRomanStringEncoding error: NULL]];
    
    //find the offset to insert it
    insertLoc = findChars(myWord,L,dStr,NO,0); //flag NO -  insertLoc is posn to insert
    
    if (insertLoc < 0) retVal = 1; //word exists at loc (-insertLoc-1)
    else retVal = 0;  //insert at insertLoc
    
    NS_HANDLER
    retVal = -1; //error
    return retVal;
    NS_ENDHANDLER
    
    if (add && (insertLoc>=0)) {
        NS_DURING
        //write the new word, followed by '\t'        
            myWord[L]='\t';
            myWord[L+1]=0;
            [dStr insertString:[NSString stringWithCString:myWord encoding: NSMacOSRomanStringEncoding] atIndex:insertLoc]; //may raise exception
            BOOL OK=[dStr writeToFile:fileName atomically: YES encoding:NSMacOSRomanStringEncoding error: NULL];
            if (!OK)  retVal = -2;
            else [self.myDictionaryManager setBackupAttributeOfItemAtPath:fileName skipBackup:NO];
        
        NS_HANDLER
        retVal = -2; //error in trying to add to or delete from dictionary.
        return retVal;
        NS_ENDHANDLER
    }
    
    else if (del && (insertLoc<0)) {
        insertLoc = (-insertLoc-1);
        NS_DURING
        //delete the word
        
        [dStr deleteCharactersInRange:NSMakeRange(insertLoc,L+1)];        
        BOOL OK=[dStr writeToFile:fileName atomically: YES encoding:NSMacOSRomanStringEncoding error: NULL];
        if (!OK)  retVal = -3;
        else [self.myDictionaryManager setBackupAttributeOfItemAtPath:fileName skipBackup:NO];
        
        NS_HANDLER
        retVal = -3; //error in trying to add to or delete from dictionary.
        return retVal;
        NS_ENDHANDLER

    }
    
    return retVal;
}

//finds last word in targetString before myChars and returns insertpoint
//flag =YES if want offset for existing word, NO if not -
// if YES, returns offset of the word, or a negative number (-(offset+1))
// if NO the  offset to insert the new word,returns (-(offset+1)) if it DOES exist
//relies on targetString being in alph order and both in uc, with an extra char eg tab between words and at end
// a c function rather than a message for speed
int  findChars(char * myChars, int N, NSString * targetString, BOOL flag,int startPoint)
{  int i=0,offset=startPoint,len;
	char ch;
	BOOL found=NO; 
	
	len = (int)[targetString length];
	if (offset<0) offset=0; //just in case passed a bad startpoint
	while ((!found)&&(i<N)&&(offset<len)) {
        if ((offset<len) && ((ch=[targetString characterAtIndex:offset+i])&&(ch<myChars[i]))) 
		{offset=offset+N+1;i=0;continue;}
        found=(ch>myChars[i]);
        if (found) break; 
        else if (ch==myChars[i]) i++;
        else {offset=offset+N+1;i=0;}
	}
	
	if (flag) {if (i==N) return offset; else return -offset-1;}
	else {if (found || (offset>=len)) return offset; else return -offset-1;}
}


- (int) addWord {
    char myWord[MAXPHRASELENGTH];
    int i,insertLoc,wLength;
    BOOL OK;
    char ch;
    NSString * fileName;
    NSMutableString * newWords;
     
    //get the word to be added - check lc -now UC- and alphabetic
    OK=YES;
    errFlag = NO;
    self.errString = @"";
    //NB this assumes pattern is not empty!
    if (theLength==0) return 0;

    [self setupMyDictionaryManager]; //in case first use after unarchiving

    if (theNumWords==1) {
         for (i=0;i<theLength;i++) {
             ch=[pattern characterAtIndex:i];
             myWord[i]=ch; 
             if ((ch<'A')||(ch>'Z')) {OK=NO; break;}
         };
         if (!OK) { 
             myWord[i+1]=0;
             errFlag = YES;
             self.errString = [NSString stringWithFormat:@"%s is not a word so cannot be added",myWord];
             return 0;
         }
     
         //set up new word contents
         fileName=[dictPath stringByAppendingPathComponent:[NSString stringWithFormat:@"words%d.txt",theLength]];
         wLength=[[[[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:NULL] objectForKey:NSFileSize] intValue];
         
         //make a new mutable stringfor wordsN.txt of capacity old+length of UnlistedWords (!)
         newWords=[NSMutableString  stringWithCapacity:wLength+theLength+1]; 
         if (!newWords) { 
             errFlag = YES;
             self.errString = [NSString stringWithFormat:@"An error occurred while reading %s; out of memory?",
                          [fileName cStringUsingEncoding: NSMacOSRomanStringEncoding]];
             return 0;
         } 
         NS_DURING
         //read in existing wordsN.txt
         [newWords appendString:[NSString stringWithContentsOfFile:fileName encoding:NSMacOSRomanStringEncoding error: NULL]];
     
         //find the offset to insert it
         insertLoc=findChars(myWord,theLength,newWords,NO,0); 
         //write the new word, followed by '\t'
         if (insertLoc>=0) {
             myWord[theLength]='\t'; 
             myWord[theLength+1]=0;
             [newWords insertString:[NSString stringWithCString:myWord encoding: NSMacOSRomanStringEncoding] atIndex:insertLoc]; //may raise exceptio	
             OK=[newWords writeToFile:fileName atomically: YES encoding:NSMacOSRomanStringEncoding error: NULL];
             if (!OK)  insertLoc=-1;
             else [self.myDictionaryManager setBackupAttributeOfItemAtPath:fileName skipBackup:NO]; //backup if user changes
         }

         NS_HANDLER
         insertLoc=-1;
         NS_ENDHANDLER
     
         if (insertLoc>=0) {
             errFlag = NO;
             self.errString = [NSString stringWithFormat:@"%s added",myWord]; //use this, tho not an error
     
             myWord[theLength]=0; //chop the tab
             //must also add to the dictionary's UserAdded file
             
             [self.myDictionaryManager addUserChange:[NSString stringWithFormat:@"%s",myWord] forDictionary:self.dictName withDate:nil adding:YES];

             self.userModified = YES;
             myDictionaryManager.needsArchiving = YES;
             
             [self.myDictionaryManager purgeChanges:self.dictName old:YES];

            return 1;
         }
         else  { //error
             myWord[theLength]=0;
             errFlag = YES;
             self.errString = [NSString stringWithFormat:@"%s not added - file error or word already exists",myWord]; //shouldn't happen
             return 0;
         }
         return 1;
        }
     
     else {//phrases 
         for (i=0;i<theFullLength;i++) {
             ch=[pattern characterAtIndex:i];
             if ((ch==',')||((ch>='A')&&(ch<='Z'))) {OK = YES;} else {OK=NO; break;}
             if (ch== ',') {myWord[i]=' ';} else {myWord[i]=ch;} 		 
         }
         if (!OK) {
             myWord[i+1]=0;
             errFlag=YES;
             self.errString=[NSString stringWithFormat:@"%s is not a legal phrase so cannot be added",myWord];
             return 0;
         }
         
         //set up new word contents
         fileName=[dictPath stringByAppendingPathComponent:[NSString stringWithFormat:@"phrases%d.txt",theFullLength]];
         wLength=[[[[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:NULL] objectForKey:NSFileSize] intValue];
                 
         //make a new mutable stringfor wordsN.txt of capacity old+length of UnlistedWords (!)
         newWords=[NSMutableString  stringWithCapacity:wLength+theFullLength+2]; 
         if (!newWords) { 
             errFlag=YES;
             self.errString=[NSString stringWithFormat:@"An error occurred while reading %s; out of memory?",
                        [fileName cStringUsingEncoding: NSMacOSRomanStringEncoding]];
             return 0;
         } 
         NS_DURING
         //read in existing wordsN.txt
         [newWords appendString:[NSString stringWithContentsOfFile:fileName encoding:NSMacOSRomanStringEncoding error: NULL]];
         
         //find the offset to insert it
         insertLoc=findChars(myWord,theFullLength,newWords,NO,0);
         //write the new word, followed by '\t'
         if (insertLoc>=0) {
             myWord[theFullLength]='\t'; 
             myWord[theFullLength+1]=0;
             [newWords insertString:[NSString stringWithCString:myWord encoding: NSMacOSRomanStringEncoding] atIndex:insertLoc]; //may raise exceptio	
             OK=[newWords writeToFile:fileName atomically: YES encoding:NSMacOSRomanStringEncoding error: NULL];
             if (!OK)  insertLoc=-1;
             else [self.myDictionaryManager setBackupAttributeOfItemAtPath:fileName skipBackup:NO];
         }
         NS_HANDLER
         insertLoc=-1;
         NS_ENDHANDLER
             
         if (insertLoc>=0) {
             errFlag=NO;
             self.errString=[NSString stringWithFormat:@"%s added",myWord];
             //and add to UserAdded for the dictionary

             myWord[theFullLength]=0;  //chop the tab 
             if (myDictionaryManager == nil) {
                 AppDelegate_iPhone* myDelegate = [[UIApplication sharedApplication] delegate];
                 self.myDictionaryManager = [(MyViewController*)[myDelegate myViewController] myDictionaryManager];
             }

             [self.myDictionaryManager addUserChange:[NSString stringWithFormat:@"%s",myWord] forDictionary:self.dictName withDate:nil adding:YES];
             self.userModified = YES;
             [self.myDictionaryManager purgeChanges:self.dictName old:YES];
             return 1;
         }
         else {
             myWord[theFullLength]=0; //chop the tab
             errFlag=YES;
             self.errString=[NSString stringWithFormat:@"%s not added - file error or word already exists",myWord]; //shouldn't happen
             return 0;
         }
        return 1;
    }
 }
 
- (int) deleteWords:(NSMutableString *)dString {
    //for a selection, it reports all deleted, but in fact only deletes the word???
	int k,totalLength, itemNo, itemLength, lastLengthUsed, wLength, numAlphChars, j, k0; //, numItems;
	char ch, ch1, myWord[MAXPHRASELENGTH];
	BOOL foundItem, isPhrase, OK;
	NSMutableString * targetString;
	NSString * targetFileName;
	int insertLoc, numItems;

    [self setupMyDictionaryManager]; //in case first use after unarchiving
    
	errFlag=NO;
	self.errString = @"";
	numItems = 0;
	
	totalLength = (int)[dString length]; //NB dString may have a trailing tab or return or spaces
    
    //replace sequence of 2 or more spaces by a \t to follow CA format and find phrases    
    k = (int)[dString replaceOccurrencesOfString:@"    " withString:@"\t" options:0 range:NSMakeRange(0, [dString length])];
    totalLength = (int)[dString length];
        
    //remove final non-alph characters
	while (totalLength>0) {
		ch = [dString characterAtIndex:totalLength-1];
		if ((ch>='A') && (ch<='Z')) {break;}
		totalLength--;
	}
    
	if (totalLength==0) {
		self.errString = @"Nothing to delete";
		return 0;
	}
 
    //is the last item only partially selected - should have exactly theLength alph chars before tab or ret -oops, we use 4 spaces!!!
    k = totalLength-1;
    numAlphChars = 1; //we have one valid char
    while (k>0) {
        ch = [dString characterAtIndex:k-1];
        if ((ch>='A') && (ch<='Z')) {
            numAlphChars++;
            if (numAlphChars > theLength) break; //not sure how this could happen!
        }
        else if ((ch == '\t') || (ch == '\n')) break;
        k--;
    }
    
    if (numAlphChars != theLength) { //we have a fragment, not a full item
        totalLength = k;
        //again remove trailing tab or ret
        while (totalLength>0) {
            ch = [dString characterAtIndex:totalLength-1];
            if ((ch>='A') && (ch<='Z')) {break;}
            totalLength--;
        }

        if (totalLength==0) {
            self.errString = @"Nothing to delete";
            return 0;
        }
    }
    
    //also check that the selection didn't pick up initial spaces etc
    k = 0;
    while (k < totalLength) {
        ch = [dString characterAtIndex:k];
        if ((ch>='A') && (ch<='Z')) {break;}
        k++;
    }
	
    if (totalLength == k) {
		self.errString = @"Nothing to delete";
		return 0;
	}
    
    //is the first item a fragment??
    j = k;
    numAlphChars = 0;
    while (j < totalLength) {
        ch = [dString characterAtIndex:j];
        if ((ch>='A') && (ch<='Z')) {
            numAlphChars++;
            if (numAlphChars > theLength) break; //not sure how this could happen!
        }
        else if ((ch == '\t') || (ch == '\n')) break;
        j++; 
    }
    
    if (numAlphChars != theLength) { //we have an initial fragment
        k = j;
        while (k < totalLength) {
            ch = [dString characterAtIndex:k];
            if ((ch>='A') && (ch<='Z')) {break;}
            k++;
        }	
        if (totalLength == k) {
            self.errString = @"Nothing to delete";
            return 0;
        }
    }
    if (totalLength == k) {
		self.errString = @"Nothing to delete";
		return 0;
	}
    
    
    k0 = k;
    //so now we examine the string from char k to char totalLength-1
    //Note we can select part of an item, so must check each item is correct
    //if a word, must be length self.theLength; if a phrase must occupy a line and at least patternLength
	
	lastLengthUsed = 0;
	itemNo = 0;
	
	itemLength = 0;
	foundItem = NO;
	isPhrase = NO;
    	
	while (k<=totalLength) {        
        if (k==totalLength) ch=0; else ch = [dString characterAtIndex:k];
		
		if ((ch>='A') && (ch<='Z')) {
			foundItem = YES;
			myWord[itemLength] = ch;
			itemLength++;
			itemNo++;
			k++;
			continue;
		}
		if ((ch==' ') && foundItem && (k < totalLength-1)) {
			k++;
			ch1 = [dString characterAtIndex:k];
			if ((ch1>='A') && (ch1<='Z')) {
				foundItem = YES;
				myWord[itemLength] = ch;
				itemLength++;
				myWord[itemLength] = ch1;
				isPhrase = YES;
				itemLength++;
				itemNo++;
				k++;
				continue;
			}
		}
		if (foundItem) {
			//delete the found item
			if (itemLength != lastLengthUsed) {//read in the approp dictionary file
				if (lastLengthUsed != 0) {
					//write to file
					OK=[targetString writeToFile:targetFileName atomically: YES encoding:NSMacOSRomanStringEncoding error: NULL];
					if (!OK) {
						errFlag = YES;
						self.errString = [NSString stringWithFormat:@"Error encountered while deleting item %d",numItems];

						//this is a bad error, dictionary possibly corrupted!
                        return numItems;
					}
				}
				if (isPhrase) {
					targetFileName = [dictPath stringByAppendingPathComponent:[NSString stringWithFormat:@"phrases%d.txt",itemLength]];
				}
				else {
					targetFileName = [dictPath stringByAppendingPathComponent:[NSString stringWithFormat:@"words%d.txt",itemLength]];
				}

				wLength=[[[[NSFileManager defaultManager] attributesOfItemAtPath:targetFileName error:NULL] objectForKey:NSFileSize] intValue];
				targetString=[[NSMutableString alloc]  initWithCapacity:wLength];

				if (!targetString) { 
					errFlag=YES;
					self.errString=[NSString stringWithFormat:@"An error occurred while reading %s; out of memory?",
									[targetFileName cStringUsingEncoding: NSMacOSRomanStringEncoding]];
                    
                    //again a bad error, hopefully never seen
					return 0;
				} 
				[targetString appendString:[NSString stringWithContentsOfFile:targetFileName encoding:NSMacOSRomanStringEncoding error: NULL]];
                
                lastLengthUsed = itemLength;
                
			}
			//find the location of the item to be deleted
			myWord[itemLength] = 0;
			
			insertLoc=findChars(myWord,itemLength,targetString,YES,0);
			//delete it
			if (insertLoc<0) { ;}//word not found - skip
			else {
                
                [targetString deleteCharactersInRange:NSMakeRange(insertLoc,itemLength+1)];
				numItems++;
                                
				}
				
			}
        
            [self.myDictionaryManager addUserChange:[NSString stringWithFormat:@"%s",myWord] forDictionary:self.dictName withDate:nil adding:NO];

			//finally reinitiaise
			itemLength = 0;
			foundItem = NO;
			isPhrase = NO;			

		k++;
	} //end while loop

	if (itemNo>0) {
		//write to file
		OK=[targetString writeToFile:targetFileName atomically: YES encoding:NSMacOSRomanStringEncoding error: NULL];
		if (!OK) {
			errFlag = YES;
			self.errString = [NSString stringWithFormat:@"Error encountered while deleting item %d",numItems];
            //bad error
			return numItems;
		}
        else [self.myDictionaryManager setBackupAttributeOfItemAtPath:targetFileName skipBackup:NO];
	}

    self.userModified = YES;
    [self.myDictionaryManager purgeChanges:self.dictName old:YES];
    myDictionaryManager.needsArchiving = YES;
    
	// report for myViewController
	if (numItems==0) {
		self.errString = @"Word not found"; //this should never happen - word was found originally!
	}
	else if (numItems==1) {
		self.errString = @"Deleted 1 item";
	}
	else  {
		self.errString = [NSString stringWithFormat:@"Deleted %d items",numItems];
	}
	return numItems;
}

#pragma mark -
#pragma mark Coding

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:dictName forKey:@"dictName"];
    //[coder encodeObject:dictPath forKey:@"dictPath"];
    //encode only the fimename (which is same as dictName, and recombine with dictionariesDirectory on restore
    // because (at least in simulatot, Application path can change- possibly also in backuo restore
    [coder encodeObject:[dictPath lastPathComponent] forKey:@"dictPath"];
    [coder encodeObject:[sourcePath lastPathComponent] forKey:@"sourcePath"];
    
    [coder encodeFloat:version forKey:@"version"];
    [coder encodeBool:userDeleted forKey:@"userDeleted"];
    [coder encodeBool:userModified forKey:@"userModified"];
    [coder encodeBool:userSupplied forKey:@"userSupplied"];
    [coder encodeBool:plusFlag forKey:@"plusFlag"];
    //other properties not encoded, must correct when dictionary changes, and for defaultDictionary
    //unarchiver must set them!!! (so setDefaultDictionary can release values -inc myDictionary
 
}

#pragma mark -
#pragma mark + menu items


- (NSMutableString*) statistics {
    NSMutableString * str;
    
    //-------
    int i;
    NSString * fName;

    int totalNumberOfWords = 0, numWords, numChars,totalNumberOfPhrases=0;
    BOOL OK=YES;
    
    str=[NSMutableString stringWithCapacity:600];
    
    [str appendFormat:@"Statistics for %@ Dictionary (ver. %4.1f):\n\n", self.dictName,self.version];
    
    for (i=2;i<MAXWORDLENGTH;i++) {
        fName=[dictPath stringByAppendingPathComponent:[NSString stringWithFormat:@"words%d.txt",i]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fName]) {
            [[NSString stringWithCString:""  encoding: NSMacOSRomanStringEncoding] writeToFile:fName atomically: YES encoding:NSMacOSRomanStringEncoding error: NULL];
            OK=NO;
        }
        numChars=[[[[NSFileManager defaultManager] attributesOfItemAtPath:fName error:NULL] objectForKey:NSFileSize] intValue];
        numWords=numChars/(i+1);
        
        if (numChars!=numWords*(i+1))        
            [str appendFormat:@"\nThe word list of length %d seems to be corrupted; searches on words of this length may fail. Remove and reinstall this dictionary.\n",i];
        
        totalNumberOfWords=totalNumberOfWords+numWords;
        
        [str appendFormat:@"wordlength %2d: %d\n",i,numWords];
                
    }
    // do the same for phrases
    
    for (i=3;i<MAXPHRASELENGTH;i++) {
        fName=[dictPath stringByAppendingPathComponent:[NSString stringWithFormat:@"phrases%d.txt",i]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fName]) {
            [[NSString stringWithCString:""  encoding: NSMacOSRomanStringEncoding] writeToFile:fName atomically: YES encoding:NSMacOSRomanStringEncoding error: NULL];
            OK=NO;
        }
        numChars=[[[[NSFileManager defaultManager] attributesOfItemAtPath:fName error:NULL] objectForKey:NSFileSize] intValue];
        numWords=numChars/(i+1);
        
        if (numChars!=numWords*(i+1)) {       
            [str appendFormat:@"\nThe phrase list of length %d seems to be corrupted; searches on words of this length may fail. Remove and reinstall this dictionary.\n",i];}
        
        totalNumberOfPhrases=totalNumberOfPhrases+numWords;
    }
    
    [str appendFormat:@"\nTOTAL number of words = %d",totalNumberOfWords];
    if (totalNumberOfPhrases==1) [str appendFormat:@" + 1 phrase"];
    else [str appendFormat:@" + %d phrases",totalNumberOfPhrases];
    
    
    if (!OK) {
        [str appendFormat:@"\nOne or more dictionary lists could not be found. Remove and reinstall this dictionary.\n"];}

    if   (self.userModified) 
        [str appendString:@"\n\nThis dictionary has been modified. See Changes"];
    //-----
    return str;
}

- (id)initWithCoder:(NSCoder *)coder {
    self.dictName = [coder decodeObjectForKey:@"dictName"];
    //for dictPath and sourcePath we encode only the filename, since the full path can change on app update or restore
    //at leats in simulator, an possibly in resrore from cloud or system uodate
    //but myDictionaryManager may not at this point exist at init
    
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES); //NSLibraryDirectory
    
     NSString *   dictionariesDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"CADictionaries"];
    
    self.dictPath = [dictionariesDirectory stringByAppendingPathComponent:[coder decodeObjectForKey:@"dictPath"]];
    self.sourcePath = [dictionariesDirectory stringByAppendingPathComponent:[coder decodeObjectForKey:@"sourcePath"]];
    
    //in prev version, "version" was incorrectly encoded as an int!!!
    //so this version should purge the archive to enforces reinstalling dictionaries
    self.version = [coder decodeFloatForKey:@"version"];
    
    
    //self.entryNumber = [coder decodeIntForKey:@"entryNumber"];
    self.userDeleted = [coder decodeBoolForKey:@"userDeleted"];
    self.userModified = [coder decodeBoolForKey:@"userModified"];
    self.userSupplied = [coder decodeBoolForKey:@"userSupplied"];
    self.plusFlag = [coder decodeBoolForKey:@"plusFlag"];
    
    
    self.myDictionaryManager = nil; //the delegate may not yet have myViewController set
    
    self.numLetters = @"";
    self.pattern = @"";
    self.anagram = @"";
    self.errString = @"";
    self.searchResults = [[NSMutableString alloc] initWithString:@""];
    
    int i;
    for (i=0;i<MAXNUMWORDS; i++) {theWordLengths[i] = 0;}
    theNumWords = 0;
    theFullLength = 0;
    searchFlag = NO;
    
    return self;
}



@end
