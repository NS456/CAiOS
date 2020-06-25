typedef	enum {
	kEnglish = 0, 
	kItalian, 
	kGerman, 
	kFrench,
    kSpanish,
    kDutch
} langTypeNum ;

typedef	enum {
    kBritishEnglish = 0,
    kAmericanEnglish,
} engTypeNum;


typedef	enum {
	kWiki = 0,
	kGoogle,
    kDictionary,
    kOnelook,
	kUser
} urlTypeNum ;

static NSString * const kDictionaryServerSite = @"http://nmsmythe.id.au/CAiOS/CAiOSDictionaries.txt";


