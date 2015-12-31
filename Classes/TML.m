/*
 *  Copyright (c) 2015 Translation Exchange, Inc. All rights reserved.
 *
 *  _______                  _       _   _             ______          _
 * |__   __|                | |     | | (_)           |  ____|        | |
 *    | |_ __ __ _ _ __  ___| | __ _| |_ _  ___  _ __ | |__  __  _____| |__   __ _ _ __   __ _  ___
 *    | | '__/ _` | '_ \/ __| |/ _` | __| |/ _ \| '_ \|  __| \ \/ / __| '_ \ / _` | '_ \ / _` |/ _ \
 *    | | | | (_| | | | \__ \ | (_| | |_| | (_) | | | | |____ >  < (__| | | | (_| | | | | (_| |  __/
 *    |_|_|  \__,_|_| |_|___/_|\__,_|\__|_|\___/|_| |_|______/_/\_\___|_| |_|\__,_|_| |_|\__, |\___|
 *                                                                                        __/ |
 *                                                                                       |___/
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */


#import "NSAttributedString+TML.h"
#import "NSObject+TML.h"
#import "NSString+TML.h"
#import "TML.h"
#import "TMLAPIBundle.h"
#import "TMLAPIClient.h"
#import "TMLApplication.h"
#import "TMLBundleManager.h"
#import "TMLDataToken.h"
#import "TMLLanguage.h"
#import "TMLLanguageCase.h"
#import "TMLLanguageSelectorViewController.h"
#import "TMLLogger.h"
#import "TMLSource.h"
#import "TMLTranslation.h"
#import "TMLTranslationActivationView.h"
#import "TMLTranslationKey.h"
#import "TMLTranslatorViewController.h"
#import "UIResponder+TML.h"
#import "UIView+TML.h"

/**
 *  Returns localized version of the string argument.
 *  The first argument is a dictionary of options, normally passed in by macros.
 *  The second argument is expected to have TML string that needs to be localized,
 *  and the rest of the arguments can be: tokens, restoration key, user options, or description.
 *
 *  The order is only relevant with respect to data types - that is, tokens (NSDictionary)
 *  will be processed before user options (NSDictionary), and restoration key (NSString) before description (NSString).
 *
 *  In the event only a single secondary NSString argument is provided - a check is made to see if options contain
 *  sender object and if that sender responds to the keyPath indicated in that string. If so - it's used as a restoration
 *  key path, otherwise - as a description.
 *  
 *  In the event user options are given among varargs, options and user options will be merged, with user options
 *  overriding values in options, but only after this method has parsed out key information from options.
 *
 *  @param options NSDictionary of options
 *  @param string  TML string
 *  @param ...     NSDictionary *tokens, NSString *restorationKeyPath, NSString *description, NDictionary *userOptions
 *
 *  @return Localized NSString or NSAttributedString, depending on token format given in options. 
 *  If options do not specify token format - NSString is returned.
 */
id TMLLocalize(NSDictionary *options, NSString *string, ...) {
    NSDictionary *tokens;
    NSString *keyPath;
    NSString *description;
    NSDictionary *userOpts;
    
    va_list args;
    va_start(args, string);
    id arg;
    while ((arg = va_arg(args, id))) {
        if ([arg isKindOfClass:[NSDictionary class]] == YES) {
            if (!tokens) {
                tokens = arg;
            }
            else if (!userOpts) {
                userOpts = arg;
            }
        }
        else if ([arg isKindOfClass:[NSString class]] == YES) {
            if (!keyPath) {
                keyPath = arg;
            }
            else if (!description) {
                description = arg;
            }
        }
    }
    va_end(args);
    
    NSMutableDictionary *ourOpts = [options mutableCopy];
    if (ourOpts == nil) {
        ourOpts = [NSMutableDictionary dictionary];
    }
    
    NSString *decorationFormat = options[TMLTokenFormatOptionName];
    if (keyPath && !description) {
        id sender = ourOpts[TMLSenderOptionName];
        id test;
        @try {
            test = [sender valueForKeyPath:keyPath];
        }
        @catch (NSException *exception) {
            description = keyPath;
            keyPath = nil;
        }
    }
    
    if (keyPath != nil) {
        ourOpts[TMLRestorationKeyOptionName] = keyPath;
    }
    
    if (userOpts != nil) {
        [ourOpts addEntriesFromDictionary:userOpts];
    }
    
    id result = nil;
    if ([decorationFormat isEqualToString:TMLAttributedTokenFormatString] == YES) {
        result = [TML localizeAttributedString:string
                                   description:description
                                        tokens:tokens
                                       options:[ourOpts copy]];
    }
    else {
        result = [TML localizeString:string
                         description:description
                              tokens:tokens
                             options:[ourOpts copy]];
    }
    return result;
}

id TMLLocalizeDate(NSDictionary *options, NSDate *date, NSString *format, ...) {
    NSString *keyPath;
    NSString *description;
    
    va_list args;
    va_start(args, format);
    id arg;
    while ((arg = va_arg(args, id))) {
        if (!description && [arg isKindOfClass:[NSString class]] == YES) {
            description = arg;
        }
        else if (description && !keyPath && [arg isKindOfClass:[NSString class]] == YES) {
            keyPath = description;
            description = arg;
        }
    }
    va_end(args);
    
    if (description && !keyPath) {
        keyPath = description;
    }
    
    NSMutableDictionary *ourOpts = [options mutableCopy];
    if (ourOpts == nil) {
        ourOpts = [NSMutableDictionary dictionary];
    }
    
    if (keyPath != nil) {
        ourOpts[TMLRestorationKeyOptionName] = keyPath;
    }
    
    NSString *dateFormat = format;
    NSString *configFormat = [[[TML sharedInstance] configuration] customDateFormatForKey:format];
    if (configFormat != nil) {
        dateFormat = configFormat;
    }
    
    NSString *decorationFormat = options[TMLTokenFormatOptionName];
    id result = nil;
    if ([decorationFormat isEqualToString:TMLAttributedTokenFormatString] == YES) {
        result = [TML localizeAttributedDate:date
                                  withFormat:dateFormat
                                 description:description
                                     options:[ourOpts copy]];
    }
    else {
        result = [TML localizeDate:date
                        withFormat:dateFormat
                       description:description
                           options:[ourOpts copy]];
    }
    
    return result;
}


@interface TML()<UIGestureRecognizerDelegate> {
    BOOL _observingNotifications;
    BOOL _checkingForBundleUpdate;
    NSDate *_lastBundleUpdateDate;
    UIGestureRecognizer *_translationActivationGestureRecognizer;
    UIGestureRecognizer *_inlineTranslationGestureRecognizer;
    TMLTranslationActivationView *_translationActivationView;
    NSHashTable *_localizationOwners;
}
@property(strong, nonatomic) TMLConfiguration *configuration;
@property(strong, nonatomic) TMLAPIClient *apiClient;
@property(nonatomic, readwrite) TMLBundle *currentBundle;
@end

@implementation TML

// Shared instance of TML
+ (TML *)sharedInstance {
    static TML *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TML alloc] init];
    });
    return sharedInstance;
}

+ (TML *) sharedInstanceWithApplicationKey:(NSString *)applicationKey
                               accessToken:(NSString *)token
{
    TMLConfiguration *config = [[TMLConfiguration alloc] initWithApplicationKey:applicationKey
                                                                    accessToken:token];
    return [self sharedInstanceWithConfiguration:config];
}

+ (TML *) sharedInstanceWithConfiguration:(TMLConfiguration *)configuration {
    TML *tml = [self sharedInstance];
    if (tml.configuration != nil) {
        TMLRaiseUnconfiguredIncovation();
    }
    tml.configuration = configuration;
    return tml;
}

#pragma mark - Class side accessors

+ (NSString *)applicationKey {
    return [[[self sharedInstance] configuration] applicationKey];
}

+ (TMLApplication *) application {
    return [[TML sharedInstance] application];
}


#pragma mark - Init

- (instancetype)init {
    return [self initWithConfiguration:nil];
}

- (instancetype) initWithConfiguration:(TMLConfiguration *)configuration {
    if (self == [super init]) {
        _localizationOwners = [NSHashTable weakObjectsHashTable];
        self.configuration = configuration;
    }
    return self;
}

- (void)setConfiguration:(TMLConfiguration *)configuration {
    if (_configuration == configuration) {
        return;
    }
    _configuration = configuration;
    if (configuration == nil) {
        self.apiClient = nil;
        [self teardownNotificationObserving];
        self.currentBundle = nil;
    }
    else {
        TMLAPIClient *apiClient = [[TMLAPIClient alloc] initWithURL:configuration.apiURL
                                                        accessToken:configuration.accessToken];
        self.apiClient = apiClient;
        [self setupNotificationObserving];
        [self initTranslationBundle:^(TMLBundle *bundle) {
            if (bundle == nil) {
                TMLWarn(@"No local translation bundle found...");
            }
            else {
                if (self.translationEnabled == NO) {
                    self.currentBundle = bundle;
                }
            }
        }];
        
        self.translationEnabled = configuration.translationEnabled;
        if (self.translationEnabled == YES) {
            TMLAPIBundle *apiBundle = (TMLAPIBundle *)[TMLBundle apiBundle];
            self.currentBundle = apiBundle;
            [apiBundle setNeedsSync];
        }
    }
}

- (void)dealloc {
    [self teardownNotificationObserving];
}

#pragma mark - Notifications

- (void) setupNotificationObserving {
    if (_observingNotifications == YES) {
        return;
    }
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    [notificationCenter addObserver:self selector:@selector(bundleSyncDidFinish:)
                               name:TMLDidFinishSyncNotification
                             object:nil];
    _observingNotifications = YES;
}

- (void) teardownNotificationObserving {
    if (_observingNotifications == NO) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _observingNotifications = NO;
}

- (void) applicationDidBecomeActive:(NSNotification *)aNotification {
    TMLBundle *currentBundle = self.currentBundle;
    if ([currentBundle isKindOfClass:[TMLAPIBundle class]] == YES) {
        [(TMLAPIBundle *)currentBundle setNeedsSync];
    }
    else {
        if ([self shouldCheckForBundleUpdate] == YES) {
            [self checkForBundleUpdate:YES completion:^(NSString *version, NSString *path, NSError *error) {
                if (version != nil && self.translationEnabled == NO) {
                    TMLBundle *newBundle = [TMLBundle bundleWithVersion:version];
                    if ([newBundle isEqualToBundle:self.currentBundle] == NO) {
                        self.currentBundle = newBundle;
                    }
                }
            }];
        }
    }
    [self setupTranslationActivationGestureRecognizer];
    if (self.translationEnabled == YES) {
        [self setupInlineTranslationGestureRecognizer];
    }
}

#pragma mark - Bundles

- (void) updateWithBundle:(TMLBundle *)bundle {
    // Special handling of nil bundles - this scenario would arise
    // when switching from API bundle to nothing - b/c no bundles are available
    // neither locally nor on CDN.
    if (bundle == nil) {
        TMLWarn(@"Setting current bundle not nil");
        self.application = nil;
    }
    else {
        TMLApplication *newApplication = [bundle application];
        TMLInfo(@"Initializing from local bundle: %@", bundle.version);
        self.application = newApplication;
        NSString *ourLocale = [self currentLocale];
        if (ourLocale != nil) {
            [bundle loadTranslationsForLocale:ourLocale completion:^(NSError *error) {
                if (error != nil) {
                    TMLError(@"Could not preload current locale '%@' into newly selected bundle: %@", ourLocale, error);
                }
                else {
                    [self restoreTMLLocalizations];
                }
            }];
        }
    }
    if ([self.application isInlineTranslationsEnabled] == NO) {
        self.configuration.translationEnabled = NO;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TMLLocalizationDataChangedNotification object:nil];
}

- (void)setCurrentBundle:(TMLBundle *)currentBundle {
    if (_currentBundle == currentBundle) {
        return;
    }
    _currentBundle = currentBundle;
    [self updateWithBundle:currentBundle];
    if ([currentBundle isKindOfClass:[TMLAPIBundle class]] == YES) {
        TMLAPIBundle *apiBundle = (TMLAPIBundle *)currentBundle;
        apiBundle.syncEnabled = YES;
        [apiBundle setNeedsSync];
    }
}

- (void) initTranslationBundle:(void(^)(TMLBundle *bundle))completion {
    // Check if there's a main bundle already set up
    TMLBundle *bundle = [TMLBundle mainBundle];

    // Check if we have a locally availale archive
    // use it if we have no main bundle, or archived version supersedes
    NSString *archivePath = [self latestLocalBundleArchivePath];
    NSString *archivedVersion = [archivePath tmlTranslationBundleVersionFromPath];
    BOOL hasNewerArchive = NO;
    if (archivedVersion != nil) {
        hasNewerArchive = [archivedVersion compareToTMLTranslationBundleVersion:bundle.version] == NSOrderedAscending;
    }
    
    TMLBundleManager *bundleManager = [TMLBundleManager defaultManager];
    
    // Install archived bundle if we got one
    if (hasNewerArchive == YES) {
        __block TMLBundle *latestArchivedBundle = nil;
        [bundleManager installBundleFromPath:archivePath completionBlock:^(NSString *path, NSError *error) {
            if (path != nil && error == nil) {
                latestArchivedBundle = [[TMLBundle alloc] initWithContentsOfDirectory:path];
            }
            if (completion != nil) {
                completion(latestArchivedBundle);
            }
        }];
        return;
    }
    if (completion != nil) {
        completion(bundle);
    }
}

- (NSArray *) findLocalBundleArchives {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:[[NSBundle mainBundle] bundlePath] error:&error];
    if (error != nil) {
        TMLError(@"Error listing main bundle files: %@", error);
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self matches '^tml_[0-9]+\\.zip'"];
    NSArray *bundles = [contents filteredArrayUsingPredicate:predicate];
    return bundles;
}

- (NSString *) latestLocalBundleArchivePath {
    NSArray *localBundleZipFiles = [self findLocalBundleArchives];
    if (localBundleZipFiles.count == 0) {
        TMLDebug(@"No local localization bundles found");
        return nil;
    }
    
    localBundleZipFiles = [localBundleZipFiles sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        NSString *aVersion = [a tmlTranslationBundleVersionFromPath];
        NSString *bVersion = [b tmlTranslationBundleVersionFromPath];
        return [aVersion compareToTMLTranslationBundleVersion:bVersion];
    }];
    NSString *latest = [localBundleZipFiles lastObject];
    latest = [[NSBundle mainBundle] pathForResource:[latest stringByDeletingPathExtension] ofType:[latest pathExtension]];
    return latest;
}

- (BOOL)shouldCheckForBundleUpdate {
    if (_checkingForBundleUpdate == YES) {
        return NO;
    }
    if (_lastBundleUpdateDate != nil) {
        NSTimeInterval sinceLastUpdate = [[NSDate date] timeIntervalSinceDate:_lastBundleUpdateDate];
        return (sinceLastUpdate > 60);
    }
    return YES;
}

/**
 *  Checks CDN for the current version info, and calls completion block when finishes.
 *
 *  The arguments passed to the completion block indicates several possible outcomes:
 *
 *     - The version argument indicates version found on CDN
 *
 *     - The path argument would indicate that a bundle was installed to that path.
 *       If path is nil - that means no installation took place - that could mean - bundle with given version is already installed.
 *
 *     - Error will indicate there was an error anywhere in the process - either fetching the version info, 
 *       or installing the new bundle.
 *
 *  @param install    Whether to install a bundle from CDN, if we don't have that version installed locally, that is...
 *  @param completion Completion block
 */
- (void) checkForBundleUpdate:(BOOL)install
                   completion:(void(^)(NSString *version, NSString *path, NSError *error))completion
{
    _checkingForBundleUpdate = YES;
    
    TMLBundleManager *bundleManager = [TMLBundleManager defaultManager];
    void(^finalize)(NSString *, NSString *, NSError *) = ^(NSString *aVersion, NSString *aPath, NSError *anError){
        dispatch_async(dispatch_get_main_queue(), ^{
            _checkingForBundleUpdate = NO;
            _lastBundleUpdateDate = [NSDate date];
            if (completion != nil) {
                completion(aVersion, aPath, anError);
            }
        });
    };
    
    [bundleManager fetchPublishedBundleInfo:^(NSDictionary *info, NSError *error) {
        NSString *version = info[TMLBundleVersionKey];
        if (version == nil) {
            NSError *error = [NSError errorWithDomain:TMLBundleManagerErrorDomain
                                                 code:TMLBundleManagerInvalidData
                                             userInfo:nil];
            finalize(version, nil, error);
            return;
        }
        
        TMLBundle *existingBundle = [TMLBundle bundleWithVersion:version];
        
        if (install == YES) {
            if (existingBundle != nil && [existingBundle isValid] == YES) {
                bundleManager.latestBundle = existingBundle;
                finalize(version, nil, nil);
            }
            else {
                NSString *defaultLocale = [self defaultLocale];
                NSString *currentLocale = [self currentLocale];
                NSMutableArray *localesToFetch = [NSMutableArray array];
                if (defaultLocale != nil) {
                    [localesToFetch addObject:defaultLocale];
                }
                if (currentLocale != nil) {
                    [localesToFetch addObject:currentLocale];
                }
                [bundleManager installPublishedBundleWithVersion:version
                                                         locales:localesToFetch
                                                 completionBlock:^(NSString *path, NSError *error) {
                                                     finalize(version, path, error);
                                                 }];
            }
        }
        else {
            finalize(version, nil, nil);
        }
    }];
}

#pragma mark - Bundle Notifications

- (void)bundleSyncDidFinish:(NSNotification *)aNotification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSDictionary *userInfo = aNotification.userInfo;
    TMLBundle *bundle = userInfo[TMLBundleChangeInfoBundleKey];
    if (bundle != nil) {
        [self updateWithBundle:bundle];
    }
}

#pragma mark - Application

- (void)setApplication:(TMLApplication *)application {
    if (_application == application) {
        return;
    }
    _application = application;
    self.configuration.defaultLocale = application.defaultLocale;
}

#pragma mark - Translating

+ (NSString *)localizeString:(NSString *)string
                 description:(NSString *)description
                      tokens:(NSDictionary *)tokens
                     options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeString:string
                                     description:description
                                          tokens:tokens
                                         options:options];
}

+ (NSAttributedString *)localizeAttributedString:(NSString *)attributedString
                                     description:(NSString *)description
                                          tokens:(NSDictionary *)tokens
                                         options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeAttributedString:attributedString
                                               description:description
                                                    tokens:tokens
                                                   options:options];
}

+ (NSString *) localizeDate:(NSDate *)date
                 withFormat:(NSString *)format
                description:(NSString *)description
                    options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeDate:date
                                    withFormat:format
                                   description:description
                                       options:options];
}

+ (NSAttributedString *)localizeAttributedDate:(NSDate *)date
                                    withFormat:(NSString *)format
                                   description:(NSString *)description
                                       options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeAttributedDate:date
                                              withFormat:format
                                             description:description
                                                 options:options];
}

+ (NSString *) localizeDate:(NSDate *)date
             withFormatName:(NSString *)formatName
                description:(NSString *)description
                    options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeDate:date
                                withFormatName:formatName
                                   description:description
                                       options:options];
}

+ (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                 withFormatName:(NSString *)formatName
                                    description:(NSString *)description
                                        options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeAttributedDate:date
                                          withFormatName:formatName
                                             description:description
                                                 options:options];
}

+ (NSString *) localizeDate:(NSDate *)date
        withTokenizedFormat:(NSString *)tokenizedFormat
             description:(NSString *)description
                    options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeDate:date
                           withTokenizedFormat:tokenizedFormat
                                   description:description
                                       options:options];
}

+ (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                            withTokenizedFormat:(NSString *)tokenizedFormat
                                 description:(NSString *)description
                                        options:(NSDictionary *)options
{
    return [[self sharedInstance] localizeAttributedDate:date
                                     withTokenizedFormat:tokenizedFormat
                                             description:description
                                                 options:options];
}

- (NSString *)localizeString:(NSString *)string
                 description:(NSString *)description
                      tokens:(NSDictionary *)tokens
                     options:(NSDictionary *)options
{
    id result = [[self currentLanguage] translate:string
                                      description:description
                                           tokens:tokens
                                          options:options];
    
    NSString *stringResult = nil;
    if ([result isKindOfClass:[NSAttributedString class]] == YES) {
        stringResult = [(NSAttributedString *)result string];
    }
    else if ([result isKindOfClass:[NSString class]] == YES) {
        stringResult = [NSString stringWithString:result];
    }
    
    return stringResult;
}

- (NSAttributedString *)localizeAttributedString:(NSString *)string
                                     description:(NSString *)description
                                          tokens:(NSDictionary *)tokens
                                         options:(NSDictionary *)options
{
    NSMutableDictionary *opts = [NSMutableDictionary dictionary];
    if (opts != nil) {
        [opts addEntriesFromDictionary:options];
    }
    opts[TMLTokenFormatOptionName] = TMLAttributedTokenFormatString;
    id result = [[self currentLanguage] translate:string
                                      description:description
                                           tokens:tokens
                                          options:opts];
    
    NSAttributedString *attributedString = nil;
    if ([result isKindOfClass:[NSAttributedString class]] == YES) {
        attributedString = [[NSAttributedString alloc] initWithAttributedString:result];
    }
    else if ([result isKindOfClass:[NSString class]] == YES) {
        attributedString = [[NSAttributedString alloc] initWithString:result attributes:nil];
    }

    return attributedString;
}

- (NSString *) localizeDate:(NSDate *)date
        withTokenizedFormat:(NSString *)tokenizedFormat
                description:(NSString *)description
                    options:(NSDictionary *)options
{
    NSDictionary *tokens = [self tokenValuesForDate:date fromTokenizedFormat:tokenizedFormat];
    return [self localizeString:tokenizedFormat
                    description:description
                         tokens:tokens
                        options:options];
}

- (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                            withTokenizedFormat:(NSString *)tokenizedFormat
                                    description:(NSString *)description
                                        options:(NSDictionary *)options
{
    NSDictionary *tokens = [self tokenValuesForDate:date fromTokenizedFormat:tokenizedFormat];
    return [self localizeAttributedString:tokenizedFormat
                              description:description
                                   tokens:tokens
                                  options:options];
}

- (NSString *) localizeDate:(NSDate *)date
              withFormatName:(NSString *)formatName
                description:(NSString *)description
                    options:(NSDictionary *)options
{
    NSString *format = [[self configuration] customDateFormatForKey: formatName];
    if (!format) return formatName;
    return [self localizeDate:date
                   withFormat:format
                  description:description
                      options:options];
}

- (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                 withFormatName:(NSString *)formatName
                                    description:(NSString *)description
                                        options:(NSDictionary *)options
{
    NSString *format = [[self configuration] customDateFormatForKey: formatName];
    if (!format) return [[NSAttributedString alloc] initWithString:formatName attributes:nil];
    return [self localizeAttributedDate:date
                             withFormat:format
                            description:description
                                options:options];
}

- (NSString *)tokenizedDateFormatFromString:(NSString *)string
                                   withDate:(NSDate *)date
                                     tokens:(NSDictionary **)tokens
{
    NSError *error = NULL;
    NSRegularExpression *expression = [NSRegularExpression
                                       regularExpressionWithPattern: @"[\\w]*"
                                       options: NSRegularExpressionCaseInsensitive
                                       error: &error];
    
    NSString *tokenizedFormat = string;
    
    NSArray *matches = [expression matchesInString:string
                                           options:0
                                             range:NSMakeRange(0, string.length)];
    NSMutableArray *elements = [NSMutableArray array];
    
    int index = 0;
    for (NSTextCheckingResult *match in matches) {
        NSString *element = [string substringWithRange:[match range]];
        [elements addObject:element];
        NSString *placeholder = [NSString stringWithFormat: @"{%d}", index++];
        tokenizedFormat = [tokenizedFormat stringByReplacingOccurrencesOfString:element
                                                                     withString:placeholder];
    }
    
    NSMutableDictionary *ourTokens = [NSMutableDictionary dictionary];
    TMLConfiguration *configuration = [self configuration];
    for (index=0; index<[elements count]; index++) {
        NSString *element = [elements objectAtIndex:index];
        NSString *tokenName = [configuration dateTokenNameForKey: element];
        NSString *placeholder = [NSString stringWithFormat: @"{%d}", index];
        
        if (tokenName) {
            tokenizedFormat = [tokenizedFormat stringByReplacingOccurrencesOfString:placeholder
                                                                         withString:tokenName];
            [ourTokens setObject:[configuration dateValueForToken:tokenName inDate:date]
                          forKey:[tokenName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]]];
        } else
            tokenizedFormat = [tokenizedFormat stringByReplacingOccurrencesOfString:placeholder
                                                                         withString:element];
    }
    if (tokens != nil) {
        *tokens = [ourTokens copy];
    }
    return tokenizedFormat;
}

- (NSString *) localizeDate:(NSDate *)date
                 withFormat:(NSString *)format
                description:(NSString *)description
                    options:(NSDictionary *)options
{
    NSDictionary *tokens = nil;
    NSString *tokenizedFormat = [self tokenizedDateFormatFromString:format
                                                           withDate:date
                                                             tokens:&tokens];
    return [self localizeString:tokenizedFormat
                    description:description
                         tokens:tokens
                        options:options];
}

- (NSAttributedString *) localizeAttributedDate:(NSDate *)date
                                     withFormat:(NSString *)format
                                    description:(NSString *)description
                                        options:(NSDictionary *)options
{
    NSDictionary *tokens = nil;
    NSString *tokenizedFormat = [self tokenizedDateFormatFromString:format
                                                           withDate:date
                                                             tokens:&tokens];
    return [self localizeAttributedString:tokenizedFormat
                              description:description
                                   tokens:tokens
                                  options:options];
}

#pragma mark - Registering new translation keys

- (void) registerMissingTranslationKey: (TMLTranslationKey *) translationKey {
    [self registerMissingTranslationKey:translationKey forSourceKey:nil];
}

- (void) registerMissingTranslationKey:(TMLTranslationKey *)translationKey
                          forSourceKey:(NSString *)sourceKey
{
    if (translationKey.label.length == 0) {
        return;
    }
    
    TMLAPIBundle *apiBundle = (TMLAPIBundle *)[TMLBundle apiBundle];
    [(TMLAPIBundle *)apiBundle addTranslationKey:translationKey forSource:sourceKey];
}

#pragma mark - Configuration

+ (void) configure:(void (^)(TMLConfiguration *config)) changes {
    changes([TML configuration]);
}

+ (TMLConfiguration *) configuration {
    return [[TML sharedInstance] configuration];
}

#pragma mark - In-App Translations

- (void)setTranslationEnabled:(BOOL)translationEnabled {
    if (_translationEnabled == translationEnabled) {
        return;
    }
    _translationEnabled = translationEnabled;
    TMLBundle *newBundle = nil;
    NSString *currentLocale = [self currentLocale];
    if (translationEnabled == YES) {
        newBundle = [TMLBundle apiBundle];
    }
    else {
        newBundle = [TMLBundle mainBundle];
    }
    self.currentBundle = newBundle;
    if ([[newBundle locales] containsObject:currentLocale] == NO) {
        [self changeLocale:[TML defaultLocale] completionBlock:nil];
    }
    self.configuration.translationEnabled = translationEnabled;
    if (translationEnabled == YES && [[UIApplication sharedApplication] keyWindow] != nil) {
        [self setupInlineTranslationGestureRecognizer];
    }
    else {
        [self teardownInlineTranslationGestureRecognizer];
    }
}

- (BOOL)isInlineTranslationsEnabled {
    if (self.application == nil) {
        // application may start up w/o any project metadata (no release available locally or on CDN)
        // however, we could still try to comminicate with the API
        return YES;
    }
    return [self.application isInlineTranslationsEnabled];
}

#pragma mark - Gesture Recognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == _inlineTranslationGestureRecognizer
        || gestureRecognizer == _translationActivationGestureRecognizer) {
        return YES;
    }
    return NO;
}

- (void) setupTranslationActivationGestureRecognizer {
    if (_translationActivationGestureRecognizer.view != nil) {
        return;
    }
    UIGestureRecognizer *gestureRecognizer = nil;
    id<TMLDelegate>delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(gestureRecognizerForTranslationActivation)] == YES) {
        gestureRecognizer = [delegate gestureRecognizerForTranslationActivation];
    }
    if (gestureRecognizer == nil) {
        gestureRecognizer = [self defaultGestureRecognizerForTranslationActivation];
    }
    [gestureRecognizer addTarget:self action:@selector(translationActivationGestureRecognized:)];
    _translationActivationGestureRecognizer = gestureRecognizer;
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow addGestureRecognizer:gestureRecognizer];
}

- (void) teardownTranslationActivationGestureRecognizer {
    if (_translationActivationGestureRecognizer.view == nil) {
        return;
    }
    [_translationActivationGestureRecognizer.view removeGestureRecognizer:_translationActivationGestureRecognizer];
    _translationActivationGestureRecognizer = nil;
}

- (void) setupInlineTranslationGestureRecognizer {
    if (_inlineTranslationGestureRecognizer.view != nil) {
        return;
    }
    
    UIGestureRecognizer *recognizer = [self createGestureRecognizerForInlineTranslation];
    [recognizer addTarget:self action:@selector(inlineTranslationGestureRecognized:)];
    recognizer.delegate = self;
    _inlineTranslationGestureRecognizer = recognizer;
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window addGestureRecognizer:recognizer];
}

- (void)teardownInlineTranslationGestureRecognizer {
    if (_inlineTranslationGestureRecognizer.view == nil) {
        return;
    }
    [_inlineTranslationGestureRecognizer.view removeGestureRecognizer:_inlineTranslationGestureRecognizer];
    _inlineTranslationGestureRecognizer = nil;
}

- (UIGestureRecognizer *)createGestureRecognizerForInlineTranslation {
    id<TMLDelegate>delegate = self.delegate;
    UIGestureRecognizer *recognizer = nil;
    if ([delegate respondsToSelector:@selector(gestureRecognizerForInlineTranslation)] == YES) {
        recognizer = [[delegate gestureRecognizerForInlineTranslation] copy];
    }
    // default recognizer
    if (recognizer == nil) {
        recognizer = [self defaultGestureRecognizerForInlineTranslation];
    }
    return recognizer;
}

- (UIGestureRecognizer *)defaultGestureRecognizerForTranslationActivation {
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] init];
#if TARGET_IPHONE_SIMULATOR
    recognizer.numberOfTouchesRequired = 2;
#else
    recognizer.numberOfTouchesRequired = 4;
#endif
    return recognizer;
}

- (UIGestureRecognizer *)defaultGestureRecognizerForInlineTranslation {
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] init];
    recognizer.numberOfTouchesRequired = 1;
    return recognizer;
}

- (void)translationActivationGestureRecognized:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (self.translationEnabled == NO) {
            [self toggleActiveTranslation:gestureRecognizer];
        }
        else {
            [self presentActiveTranslationOptions];
        }
    }
}

- (void)presentActiveTranslationOptions {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:TMLLocalizedString(@"Choose")
                                                                             message:TMLLocalizedString(@"What would you like to do?")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *changeLocaleAction = [UIAlertAction actionWithTitle:TMLLocalizedString(@"Change Language") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self presentLanguageSelectorController];
    }];
    [alertController addAction:changeLocaleAction];
    
    UIAlertAction *disableAction = [UIAlertAction actionWithTitle:TMLLocalizedString(@"Deactivate Translation") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self toggleActiveTranslation:disableAction];
    }];
    [alertController addAction:disableAction];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:TMLLocalizedString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissPresentedViewController];
    }];
    [alertController addAction:cancel];
    
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController animated:YES completion:nil];
}

- (void)toggleActiveTranslation:(id)sender {
    BOOL translationEnabled = self.translationEnabled;
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIColor *backgroundColor = nil;
    
    if (_translationActivationView == nil) {
        _translationActivationView = [[TMLTranslationActivationView alloc] initWithFrame:window.bounds];
    }
    
    if (translationEnabled) {
        backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.77];
    }
    else {
        backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.77];
    }
    _translationActivationView.backgroundColor = [UIColor clearColor];
    [UIView animateWithDuration:0.13 animations:^{
        _translationActivationView.backgroundColor = backgroundColor;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.13 animations:^{
            _translationActivationView.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            [_translationActivationView removeFromSuperview];
        }];
    }];
    
    if (_translationActivationView.superview == nil) {
        [window addSubview:_translationActivationView];
    }
    self.translationEnabled = !self.translationEnabled;
}

- (void)inlineTranslationGestureRecognized:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    UIView *view = gestureRecognizer.view;
    CGPoint location = [gestureRecognizer locationInView:view];
    __block UIView *hitView = [view hitTest:location withEvent:nil];
    __block NSSet *localizablePaths = [hitView tmlLocalizableKeyPaths];
    if (localizablePaths.count == 0) {
        [hitView tmlIterateSubviewsWithBlock:^(UIView *view, BOOL *skip, BOOL *stop) {
            CGPoint location = [gestureRecognizer locationInView:view];
            if (CGRectContainsPoint(view.bounds, location) == NO) {
                *skip = YES;
            }
            else {
                localizablePaths = [view tmlLocalizableKeyPaths];
                if (localizablePaths.count > 0) {
                    hitView = view;
                    *stop = YES;
                }
            }
        }];
    }
    
    [self translateLocalizablePropertiesOfView:hitView];
}

#pragma mark - Translating view properties

- (void)translateLocalizablePropertiesOfView:(UIView *)view {
    if (view == nil) {
        return;
    }
    
    NSDictionary *translationKeys = [view tmlTranslationKeysAndPaths];
    NSArray *allKeyPaths = [translationKeys allKeys];
    if (allKeyPaths.count == 0) {
        allKeyPaths = [[view tmlLocalizableKeyPaths] allObjects];
    }
    
    if (allKeyPaths.count == 1) {
        [self translateView:view valueKeyPath:[allKeyPaths firstObject]];
    }
    else {
        // TODO: present chooser
    }
}

- (void)translateView:(UIView *)view valueKeyPath:(NSString *)keyPath {
    NSString *key = [view tmlTranslationKeyForKeyPath:keyPath];
    
    if (key == nil || [self isTranslationKeyRegistered:key] == NO) {
        id value = [view valueForKeyPath:keyPath];
        NSString *valueString = nil;
        NSString *shortString = nil;
        if ([value isKindOfClass:[NSString class]] == YES) {
            valueString = value;
            shortString = value;
        }
        else if ([value isKindOfClass:[NSAttributedString class]] == YES) {
            NSAttributedString *attributedValue = (NSAttributedString *)value;
            valueString = [attributedValue tmlAttributedString:nil];
            shortString = [attributedValue string];
        }
        
        TMLTranslationKey *translationKey = [[TMLTranslationKey alloc] init];
        translationKey.locale = [TML defaultLocale];
        translationKey.label = valueString;
        
        NSDictionary *tokens = nil;
        if ([value isKindOfClass:[NSAttributedString class]] == YES) {
            [(NSAttributedString *)value tmlAttributedString:&tokens];
        }
        
        if ([[TML sharedInstance] isTranslationKeyRegistered:translationKey.key] == YES) {
            [self presentTranslatorViewControllerWithTranslationKey:key];
        }
        else {
            NSInteger maxChars = 32;
            shortString = (shortString.length > maxChars) ? [[shortString substringToIndex:maxChars] stringByAppendingString:@"..."] : shortString;
            NSString *message = TMLLocalizedString(@"Could not find translation key for string \"{value}\"", @{@"value": shortString});
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:TMLLocalizedString(@"Add new string?")
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:TMLLocalizedString(@"Yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSMutableDictionary *payload = [NSMutableDictionary dictionary];
                NSString *source = [self currentSource];
                payload[source] = [NSSet setWithObject:translationKey];
                TMLInfo(@"Registering new translation key '%@' for user translation", translationKey.key);
                [self.apiClient registerTranslationKeysBySourceKey:payload completionBlock:^(BOOL success, NSError *error) {
                    if (success == YES) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.33 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self presentTranslatorViewControllerWithTranslationKey:key];
                        });
                    }
                    else {
                        [self showError:error];
                    }
                }];
            }];
            [alert addAction:acceptAction];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:TMLLocalizedString(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:cancelAction];
            [self presentAlertController:alert];
        }
    }
    else {
        [self presentTranslatorViewControllerWithTranslationKey:key];
    }
}

#pragma mark - Showing Errors

- (void)showError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:TMLLocalizedString(@"Error")
                                                                   message:[error localizedDescription]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:TMLLocalizedString(@"OK") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:okAction];
    [self presentAlertController:alert];
}

#pragma mark - Presenting View Controllers

+ (void)presentTranslatorViewControllerWithTranslationKey:(NSString *)translationKey {
    [[TML sharedInstance] presentTranslatorViewControllerWithTranslationKey:translationKey];
}

- (void)presentTranslatorViewControllerWithTranslationKey:(NSString *)translationKey {
    TMLTranslatorViewController *translator = [[TMLTranslatorViewController alloc] initWithTranslationKey:translationKey];
    [self presentViewController:translator];
}

+ (void)presentLanguageSelectorController {
    [[TML sharedInstance] presentLanguageSelectorController];
}

- (void)presentLanguageSelectorController {
    TMLLanguageSelectorViewController *languageSelector = [[TMLLanguageSelectorViewController alloc] init];
    languageSelector.automaticallyAdjustsScrollViewInsets = YES;
    [self presentViewController:languageSelector];
}

- (UIViewController *)defaultPresentingViewController {
    UIViewController *presenter = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    return presenter;
}

- (void)presentAlertController:(UIAlertController *)alertController {
    [self _presentViewController:alertController];
}

- (void)presentViewController:(UIViewController *)viewController {
    UINavigationController *wrapper = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self _presentViewController:wrapper];
}

- (void)_presentViewController:(UIViewController *)viewController {
    UIViewController *presenter = [self defaultPresentingViewController];
    if (presenter.presentedViewController != nil) {
        [presenter dismissViewControllerAnimated:YES completion:^{
            [presenter presentViewController:viewController animated:YES completion:nil];
        }];
    }
    else {
        [presenter presentViewController:viewController animated:YES completion:nil];
    }
}

- (void)dismissPresentedViewController {
    [self dismissPresentedViewController:nil];
}

- (void)dismissPresentedViewController:(void (^)(void))completion {
    UIViewController *presenter = [self defaultPresentingViewController];
    if (presenter.presentedViewController != nil) {
        [presenter dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Block Options

+ (void) beginBlockWithOptions:(NSDictionary *) options {
    [[TML sharedInstance] beginBlockWithOptions:options];
}

+ (NSObject *) blockOptionForKey: (NSString *) key {
    return [[TML sharedInstance] blockOptionForKey: key];
}

+ (void) endBlockWithOptions {
    [[TML sharedInstance] endBlockWithOptions];
}

- (void) beginBlockWithOptions:(NSDictionary *) options {
    if (self.blockOptions == nil)
        self.blockOptions = [NSMutableArray array];
    
    [self.blockOptions insertObject:options atIndex:0];
}

- (NSDictionary *) currentBlockOptions {
    if (self.blockOptions == nil)
        self.blockOptions = [NSMutableArray array];
    
    if ([self.blockOptions count] == 0)
        return [NSDictionary dictionary];

    return [self.blockOptions objectAtIndex:0];
}

- (NSObject *) blockOptionForKey: (NSString *) key {
    return [[self currentBlockOptions] objectForKey:key];
}

- (void) endBlockWithOptions {
    if (self.blockOptions == nil)
        return;
    
    if ([self.blockOptions count] == 0)
        return;
    
    [self.blockOptions removeObjectAtIndex:0];
}

#pragma mark - Sources

+ (NSString *) currentSource {
    return [[self sharedInstance] currentSource];
}

- (void)setCurrentSource:(NSString *)currentSource {
    if (currentSource != nil) {
        [self beginBlockWithOptions:@{TMLSourceOptionName : currentSource}];
    }
}

- (NSString *)currentSource {
    NSString *source = (NSString *)[self blockOptionForKey:TMLSourceOptionName];
    if (source == nil) {
        source = [[TMLSource defaultSource] key];
    }
    return source;
}

#pragma mark - Languages and Locales

+ (TMLLanguage *) defaultLanguage {
    return [[TML sharedInstance] defaultLanguage];
}

- (TMLLanguage *)defaultLanguage {
    return [[self application] languageForLocale:[self defaultLocale]];
}

+ (NSString *)defaultLocale {
    return [[TML sharedInstance] defaultLocale];
}

- (NSString *)defaultLocale {
    return self.configuration.defaultLocale;
}

+ (TMLLanguage *) currentLanguage {
    return [[TML sharedInstance] currentLanguage];
}

- (TMLLanguage *)currentLanguage {
    TMLLanguage *lang = [[self application] languageForLocale:[self currentLocale]];
    if (lang == nil) {
        lang = [TMLLanguage defaultLanguage];
    }
    return lang;
}

+ (NSString *)currentLocale {
    return [[TML sharedInstance] currentLocale];
}

- (NSString *)currentLocale {
    return self.configuration.currentLocale;
}

+ (NSString *)previousLocale {
    return [[TML sharedInstance] previousLocale];
}

- (NSString *)previousLocale {
    return self.configuration.previousLocale;
}

+ (void) changeLocale:(NSString *)locale
      completionBlock:(void(^)(BOOL success))completionBlock
{
    [[TML sharedInstance] changeLocale:locale
                       completionBlock:completionBlock];
}

- (void) changeLocale:(NSString *)locale
      completionBlock:(void(^)(BOOL success))completionBlock
{
    void(^finalize)(BOOL) = ^(BOOL success) {
        if (success == YES) {
            [self _changeToLocale:locale];
        }
        if (completionBlock != nil) {
            completionBlock(success);
        }
    };
    TMLBundle *ourBundle = self.currentBundle;
    if ([ourBundle translationsForLocale:locale] == nil) {
        [ourBundle loadTranslationsForLocale:locale completion:^(NSError *error) {
            TMLLanguage *newLanguage;
            if (error == nil) {
                newLanguage = [self.application languageForLocale:locale];
            }
            BOOL success = newLanguage != nil;
            finalize(success);
        }];
    }
    else {
        finalize(YES);
    }
}

- (void)_changeToLocale:(NSString *)locale {
    TMLLanguage *newLanguage = [self.application languageForLocale:locale];
    if (newLanguage == nil) {
        return;
    }
    // TODO: do we really need toi change both ourselves and config?
    NSString *oldLocale = self.configuration.currentLocale;
    TMLConfiguration *config = self.configuration;
    config.previousLocale = oldLocale;
    config.currentLocale = newLanguage.locale;
    [self didChangeFromLocale:oldLocale];
}

- (void)didChangeFromLocale:(NSString *)previousLocale {
    [self restoreTMLLocalizations];
    NSDictionary *info = @{
                           TMLPreviousLocaleUserInfoKey: previousLocale
                           };
    [[NSNotificationCenter defaultCenter] postNotificationName:TMLLanguageChangedNotification
                                                        object:nil
                                                      userInfo:info];
}

#pragma mark - Translations

- (NSArray *) translationsForKey:(NSString *)translationKey locale:(NSString *)locale {
    NSDictionary *translations = [self.currentBundle translationsForLocale:locale];
    return translations[translationKey];
}

- (NSArray *)translationKeysMatchingString:(NSString *)string
                                    locale:(NSString *)locale
{
    NSArray *results = [self.currentBundle translationKeysMatchingString:string
                                                                  locale:locale];
    return results;
}

- (BOOL)isTranslationKeyRegistered:(NSString *)translationKey {
    if ([self.currentBundle isKindOfClass:[TMLAPIBundle class]] == YES) {
        TMLAPIBundle *apiBundle = (TMLAPIBundle *)self.currentBundle;
        TMLTranslationKey *registeredKey = [[apiBundle translationKeys] valueForKey:translationKey];
        return registeredKey != nil;
    }
    NSArray *results = [self translationsForKey:translationKey locale:[self currentLocale]];
    return results != nil;
}

+ (void) reloadTranslations {
    [[TML sharedInstance] reloadTranslations];
}

- (void) reloadTranslations {
    TMLBundle *ourBundle = self.currentBundle;
    if ([ourBundle isKindOfClass:[TMLAPIBundle class]] == YES) {
        [(TMLAPIBundle *)ourBundle setNeedsSync];
    }
}

- (void)restoreTMLLocalizations {
    NSMutableSet *toRestore = [NSMutableSet set];
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (keyWindow != nil) {
        [toRestore addObject:keyWindow];
    }
    
    UIViewController *rootViewController = [keyWindow rootViewController];
    if (rootViewController != nil) {
        [toRestore addObject:rootViewController];
    }
    
    id firstResponder = [keyWindow tmlFindFirstResponder];
    if (firstResponder != nil) {
        [toRestore addObject:firstResponder];
    }
    
    NSArray *owners = [_localizationOwners allObjects];
    [toRestore addObjectsFromArray:owners];
    
    for (id obj in toRestore) {
        if (obj == self) {
            continue;
        }
        [obj restoreTMLLocalizations];
    }
}

- (BOOL) hasLocalTranslationsForLocale:(NSString *)locale {
    if (locale == nil) {
        return NO;
    }
    TMLBundle *bundle = self.currentBundle;
    return [bundle translationsForLocale:locale] != nil;
}

#pragma mark - Utility Methods

- (NSDictionary *) tokenValuesForDate: (NSDate *) date fromTokenizedFormat:(NSString *) tokenizedFormat {
    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    
    NSArray *matches = [[TMLDataToken expression] matchesInString: tokenizedFormat options: 0 range: NSMakeRange(0, [tokenizedFormat length])];
    for (NSTextCheckingResult *match in matches) {
        NSString *tokenName = [tokenizedFormat substringWithRange:[match range]];
        
        if (tokenName) {
            [tokens setObject:[[self configuration] dateValueForToken: tokenName inDate:date] forKey:[tokenName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]]];
        }
    }
    
    return tokens;
}

- (void)removeLocalizationData {
    [[TMLBundleManager defaultManager] removeAllBundles];
    [self setCurrentBundle:nil];
    _lastBundleUpdateDate = nil;
}

#pragma mark -
- (void)registerLocalizedStringOwner:(id)owner {
    [_localizationOwners addObject:owner];
}

@end
