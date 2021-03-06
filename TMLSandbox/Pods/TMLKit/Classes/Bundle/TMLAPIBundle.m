//
//  TMLAPIBundle.m
//  Demo
//
//  Created by Pasha on 11/20/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "NSObject+TMLJSON.h"
#import "TML.h"
#import "TMLAPIBundle.h"
#import "TMLAPIClient.h"
#import "TMLAPIResponse.h"
#import "TMLApplication.h"
#import "TMLBundleManager.h"
#import "TMLConfiguration.h"
#import "TMLLanguage.h"
#import "TMLSource.h"
#import "TMLTranslationKey.h"

@interface TMLBundle()
- (void)resetData;
@end

@interface TMLAPIBundle() {
    BOOL _needsSync;
    NSMutableArray *_syncErrors;
    NSInteger _syncOperationCount;
}
@property (strong, nonatomic) NSArray *sources;
@property (readwrite, nonatomic) NSArray *languages;
@property (readwrite, nonatomic) TMLApplication *application;
@property (readwrite, nonatomic) NSDictionary *translations;
@property (readwrite, nonatomic) NSDictionary *translationKeys;
@property (readwrite, nonatomic) NSMutableDictionary *addedTranslationKeys;
@property (strong, nonatomic) NSOperationQueue *syncQueue;
@end

@implementation TMLAPIBundle

@dynamic sources, languages, application, translations, translationKeys;

- (NSURL *)sourceURL {
    return [[[TML sharedInstance] configuration] apiURL];
}

- (BOOL)isMutable {
    return YES;
}

#pragma mark - Languages

- (void)addLanguage:(TMLLanguage *)language {
    NSMutableArray *newLanguages = [NSMutableArray arrayWithObject:language];
    NSArray *existingLanguages = self.languages;
    for (TMLLanguage *lang in existingLanguages) {
        if ([lang.locale isEqualToString:language.locale] == NO) {
            [newLanguages addObject:lang];
        }
    }
    self.languages = newLanguages;
}

#pragma mark - Locales

/**
 *  Cleans up bundle by removing locales that are not in the list of effective locales
 *
 *  @param locales Effective locales
 */
- (void)cleanupLocales:(NSArray *)locales {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.path error:&error];
    if (error != nil) {
        TMLError(@"Error cleaning up locales of the API bundle: %@", error);
        return;
    }
    BOOL isDir = NO;
    for (NSString *path in contents) {
        NSString *fullPath = [self.path stringByAppendingPathComponent:path];
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDir] == NO
            || isDir == NO) {
            continue;
        }
        if ([locales containsObject:path] == YES) {
            continue;
        }
        if ([fileManager removeItemAtPath:fullPath error:&error] == NO) {
            TMLError(@"Error cleaning up locale '%@' of API bundle: %@", path, error);
        }
    }
}

#pragma mark - Translations
- (void)loadTranslationsForLocale:(NSString *)aLocale
                       completion:(void (^)(NSError *))completion {
    [self loadTranslationsForLocale:aLocale
                requireLanguageData:YES
                         completion:completion];
}

- (void)loadTranslationsForLocale:(NSString *)aLocale
              requireLanguageData:(BOOL)requireLanguageData
                       completion:(void (^)(NSError *))completion
{
    TMLAPIClient *client = [[TML sharedInstance] apiClient];
    
    NSString *languageFilePath = [[[self path] stringByAppendingPathComponent:aLocale] stringByAppendingPathComponent:TMLBundleLanguageFilename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:languageFilePath] == NO && requireLanguageData == YES) {
        [client getLanguageForLocale:aLocale
                             options:nil
                     completionBlock:^(TMLLanguage *language, TMLAPIResponse *response, NSError *error) {
                         NSError *fileError;
                         if (language != nil) {
                             [self addLanguage:language];
                             NSData *writeData = [[response.userInfo tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *relativePath = [aLocale stringByAppendingPathComponent:TMLBundleLanguageFilename];
                             [self writeResourceData:writeData
                                      toRelativePath:relativePath
                                               error:&fileError];
                         }
                         [self loadTranslationsForLocale:aLocale requireLanguageData:NO completion:completion];
                     }];
        return;
    }
    
    [client getTranslationsForLocale:aLocale
                              source:nil
                             options:nil
                     completionBlock:^(NSDictionary *translations, TMLAPIResponse *response, NSError *error) {
                         if (translations != nil) {
                             [self setTranslations:translations forLocale:aLocale];
                             NSDictionary *jsonObj = @{TMLAPIResponseResultsKey: response.results};
                             NSData *writeData = [[jsonObj tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                             NSString *relativePath = [aLocale stringByAppendingPathComponent:TMLBundleTranslationsFilename];
                             
                             NSError *fileError;
                             [self writeResourceData:writeData
                                      toRelativePath:relativePath
                                               error:&fileError];
                             if (error == nil && fileError != nil) {
                                 error = fileError;
                             }
                         }
                         if (completion != nil) {
                             completion(error);
                         }
    }];
}

- (void)setTranslations:(NSDictionary *)translations forLocale:(NSString *)locale {
    NSMutableDictionary *allTranslations = [self.translations mutableCopy];
    if (allTranslations == nil) {
        allTranslations = [NSMutableDictionary dictionary];
    }
    
    if (translations.count == 0
        && allTranslations[locale] != nil) {
        allTranslations[locale] = nil;
    }
    else {
        allTranslations[locale] = translations;
    }
    
    self.translations = allTranslations;
}

- (void)addTranslationKey:(TMLTranslationKey *)translationKey
                forSource:(NSString *)sourceKey
{
    if (translationKey.label.length == 0) {
        return;
    }
    
    NSMutableDictionary *addedTranslationKeys = self.addedTranslationKeys;
    if (addedTranslationKeys == nil) {
        addedTranslationKeys = [NSMutableDictionary dictionary];
    }
    
    @synchronized(_addedTranslationKeys) {
        NSString *effectiveSourceKey = sourceKey;
        if (effectiveSourceKey == nil) {
            effectiveSourceKey = TMLSourceDefaultKey;
        }
        
        NSMutableSet *keys = addedTranslationKeys[effectiveSourceKey];
        if (keys == nil) {
            keys = [NSMutableSet set];
        }
        
        [keys addObject:translationKey];
        addedTranslationKeys[effectiveSourceKey] = keys;
        self.addedTranslationKeys = addedTranslationKeys;
    }
    
}

- (void)removeAddedTranslationKeys:(NSDictionary *)translationKeys {
    @synchronized(_addedTranslationKeys) {
        if (_addedTranslationKeys.count == 0) {
            return;
        }
        
        for (NSString *source in translationKeys) {
            NSMutableSet *keys = [_addedTranslationKeys[source] mutableCopy];
            for (TMLTranslationKey *key in translationKeys[source]) {
                [keys removeObject:key];
            }
            _addedTranslationKeys[source] = keys;
        }
    }
}

- (void)setAddedTranslationKeys:(NSMutableDictionary *)addedTranslationKeys {
    if (_addedTranslationKeys == addedTranslationKeys
        || [_addedTranslationKeys isEqualToDictionary:addedTranslationKeys] == YES) {
        return;
    }
    _addedTranslationKeys = addedTranslationKeys;
    [self didAddTranslationKeys];
}

- (void)didAddTranslationKeys {
    if (TMLSharedConfiguration().neverSubmitNewTranslationKeys == YES) {
        return;
    }
    [self setNeedsSync];
}

#pragma mark - Resource handling

- (BOOL)writeResourceData:(NSData *)data
           toRelativePath:(NSString *)relativeResourcePath
                    error:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *destinationPath = [self.path stringByAppendingPathComponent:relativeResourcePath];
    NSString *destinationDir = [destinationPath stringByDeletingLastPathComponent];
    NSError *fileError = nil;
    if ([fileManager fileExistsAtPath:destinationDir] == NO) {
        if ([fileManager createDirectoryAtPath:destinationDir
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&fileError] == NO) {
            TMLError(@"Error creating resource directory: %@", fileError);
        }
    }
    if (fileError == nil
        && [data writeToFile:destinationPath options:NSDataWritingAtomic error:&fileError] == NO){
        TMLError(@"Error write resource data: %@", fileError);
    }
    if (error != nil && fileError != nil) {
        *error = fileError;
    }
    return (fileError != nil);
}

#pragma mark - Sync

- (BOOL)isSyncing {
    return _syncOperationCount > 0;
}

-(void)setNeedsSync {
    _needsSync = YES;
    if (self.syncEnabled == NO) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(sync)
                                               object:nil];
    
    NSTimeInterval delay = 0.;
    NSArray *availableLocales = [self availableLocales];
    if (availableLocales.count > 0
        && [availableLocales containsObject:TMLCurrentLocale()] == YES) {
        delay = 3.;
    }
    [self performSelector:@selector(sync)
               withObject:nil
               afterDelay:delay];
}

- (NSOperationQueue *)syncQueue {
    if (_syncQueue == nil) {
        _syncQueue = [[NSOperationQueue alloc] init];
    }
    return _syncQueue;
}

- (void)addSyncOperation:(NSOperation *)syncOperation {
    NSOperationQueue *syncQueue = self.syncQueue;
    [syncQueue addOperation:syncOperation];
    _syncOperationCount++;
    if (_syncOperationCount == 1) {
        [[TMLBundleManager defaultManager] notifyBundleMutation:TMLDidStartSyncNotification
                                                         bundle:self
                                                         errors:nil];
    }
}

- (void)cancelSync {
    if (_syncOperationCount == 0) {
        return;
    }
    NSOperationQueue *syncQueue = self.syncQueue;
    [syncQueue cancelAllOperations];
    _syncOperationCount = 0;
}

- (void)sync {
    if (self.syncEnabled == NO) {
        [self setNeedsSync];
        return;
    }
    if (_syncOperationCount > 0) {
        return;
    }
    
    _needsSync = NO;
    
    NSOperationQueue *syncQueue = self.syncQueue;
    syncQueue.suspended = YES;
    
    [self syncMetaData];
    NSMutableArray *locales = [self.availableLocales mutableCopy];
    if (locales == nil) {
        locales = [NSMutableArray array];
    }
    
    NSString *defaultLocale = TMLDefaultLocale();
    if (defaultLocale != nil && [locales containsObject:defaultLocale] == NO) {
        [locales addObject:defaultLocale];
    }
    
    NSString *currentLocale = TMLCurrentLocale();
    if (currentLocale != nil && [locales containsObject:currentLocale] == NO) {
        [locales addObject:currentLocale];
    }
    
    if (locales.count > 0) {
        [self syncLocales:locales];
    }
    [self syncAddedTranslationKeys];
    syncQueue.suspended = NO;
}

- (void)syncMetaData {
    TMLAPIClient *client = [[TML sharedInstance] apiClient];
    [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
        [client getCurrentApplicationWithOptions:@{TMLAPIOptionsIncludeDefinition: @YES}
                                 completionBlock:^(TMLApplication *application, TMLAPIResponse *response, NSError *error) {
                                     NSError *fileError;
                                     if (application != nil) {
                                         self.application = application;
                                         NSArray *appLocales = [application.languages valueForKeyPath:@"locale"];
                                         [self cleanupLocales:appLocales];
                                         NSData *writeData = [[response.userInfo tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                                         [self writeResourceData:writeData
                                                  toRelativePath:TMLBundleApplicationFilename
                                                           error:&fileError];
                                     }
                                     NSMutableArray *errors = [NSMutableArray array];
                                     if (error != nil) {
                                         [errors addObject:error];
                                     }
                                     if (fileError != nil) {
                                         [errors addObject:fileError];
                                     }
                                     
                                     [self didFinishSyncOperationWithErrors:errors];
                                 }];
    }]];
    
    [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
        [client getSources:nil
           completionBlock:^(NSArray *sources, TMLAPIResponse *response, NSError *error) {
               NSError *fileError;
               if (sources != nil) {
                   self.sources = sources;
                   NSDictionary *jsonObj = @{TMLAPIResponseResultsKey: response.results};
                   [self writeResourceData:[[jsonObj tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding]
                            toRelativePath:TMLBundleSourcesFilename
                                     error:&fileError];
               }
               NSMutableArray *errors = [NSMutableArray array];
               if (error != nil) {
                   [errors addObject:error];
               }
               if (fileError != nil) {
                   [errors addObject:fileError];
               }
               
               [self didFinishSyncOperationWithErrors:errors];
           }];
    }]];
    
    [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
        [client getTranslationKeysWithOptions:nil
                              completionBlock:^(NSArray *translationKeys, TMLAPIResponse *response, NSError *error) {
                                  NSError *fileError;
                                  if (translationKeys != nil) {
                                      NSMutableDictionary *newKeys = [NSMutableDictionary dictionary];
                                      for (TMLTranslationKey *translationKey in translationKeys) {
                                          newKeys[translationKey.key] = translationKey;
                                      }
                                      self.translationKeys = newKeys;
                                      NSDictionary *jsonObj = @{TMLAPIResponseResultsKey: response.results};
                                      [self writeResourceData:[[jsonObj tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding]
                                               toRelativePath:TMLBundleTranslationKeysFilename
                                                        error:&fileError];
                                  }
                                  NSMutableArray *errors = [NSMutableArray array];
                                  if (error != nil) {
                                      [errors addObject:error];
                                  }
                                  if (fileError != nil) {
                                      [errors addObject:fileError];
                                  }
                                  [self didFinishSyncOperationWithErrors:errors];
                              }];
    }]];
}

- (void)syncLocales:(NSArray *)locales {
    if (locales.count == 0) {
        return;
    }
    
    TMLAPIClient *client = [[TML sharedInstance] apiClient];
    for (NSString *aLocale in locales) {
        NSString *locale = [aLocale lowercaseString];
        // fetch translation
        [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
            [client getTranslationsForLocale:locale
                                      source:nil
                                     options:nil
                             completionBlock:^(NSDictionary *translations, TMLAPIResponse *response, NSError *error) {
                                 NSError *fileError;
                                 if (translations != nil) {
                                     [self setTranslations:translations forLocale:locale];
                                     NSDictionary *jsonObj = @{TMLAPIResponseResultsKey: response.results};
                                     NSData *writeData = [[jsonObj tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                                     NSString *relativePath = [locale stringByAppendingPathComponent:TMLBundleTranslationsFilename];
                                     
                                     [self writeResourceData:writeData
                                              toRelativePath:relativePath
                                                       error:&fileError];
                                 }
                                 NSMutableArray *errors = [NSMutableArray array];
                                 if (error != nil) {
                                     [errors addObject:error];
                                 }
                                 if (fileError != nil) {
                                     [errors addObject:fileError];
                                 }
                                 [self didFinishSyncOperationWithErrors:errors];
                             }];
        }]];
        
        // fetch language definition
        [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
            [client getLanguageForLocale:locale
                                 options:@{TMLAPIOptionsIncludeDefinition: @YES}
                         completionBlock:^(TMLLanguage *language, TMLAPIResponse *response, NSError *error) {
                             NSError *fileError;
                             if (language != nil) {
                                 [self addLanguage:language];
                                 NSData *writeData = [[response.userInfo tmlJSONString] dataUsingEncoding:NSUTF8StringEncoding];
                                 NSString *relativePath = [locale stringByAppendingPathComponent:TMLBundleLanguageFilename];
                                 [self writeResourceData:writeData
                                          toRelativePath:relativePath
                                                   error:&fileError];
                             }
                             
                             NSMutableArray *errors = [NSMutableArray array];
                             if (error != nil) {
                                 [errors addObject:error];
                             }
                             if (fileError != nil) {
                                 [errors addObject:fileError];
                             }
                             
                             [self didFinishSyncOperationWithErrors:errors];
                         }];
        }]];
    }
}

- (void)syncAddedTranslationKeys {
    if (TMLSharedConfiguration().neverSubmitNewTranslationKeys == YES) {
        return;
    }
    if (_addedTranslationKeys.count == 0) {
        return;
    }
    NSMutableDictionary *missingTranslations = self.addedTranslationKeys;
    BOOL hasKeys = NO;
    for (NSString *source in missingTranslations) {
        NSArray *value = missingTranslations[source];
        if (value.count > 0) {
            hasKeys = YES;
            break;
        }
    }
    if (hasKeys == NO) {
        return;
    }
    [self addSyncOperation:[NSBlockOperation blockOperationWithBlock:^{
        [[[TML sharedInstance] apiClient] registerTranslationKeysBySourceKey:missingTranslations
                                                             completionBlock:^(BOOL success, NSError *error) {
                                                                 if (success == YES) {
                                                                     [self removeAddedTranslationKeys:missingTranslations];
                                                                 }
                                                                 NSArray *errors = (error != nil) ? @[error] : nil;
                                                                 [self didFinishSyncOperationWithErrors:errors];
                                                             }];
    }]];
}

- (void)didFinishSyncOperationWithErrors:(NSArray *)errors {
    _syncOperationCount--;
    if (_syncOperationCount < 0) {
        TMLWarn(@"Unbalanced call to %s", __PRETTY_FUNCTION__);
        _syncOperationCount = 0;
    }
    if (_syncErrors == nil) {
        _syncErrors = [NSMutableArray array];
    }
    if (errors.count > 0) {
        [_syncErrors addObjectsFromArray:errors];
    }
    
    TMLBundleManager *bundleManager = [TMLBundleManager defaultManager];
    [bundleManager notifyBundleMutation:TMLLocalizationDataChangedNotification
                                 bundle:self
                                 errors:errors];
    
    if (_syncOperationCount == 0) {
        [self resetData];
        if (_needsSync == YES) {
            [self performSelector:@selector(sync) withObject:nil afterDelay:3.0];
        }
        [bundleManager notifyBundleMutation:TMLDidFinishSyncNotification
                                     bundle:self
                                     errors:_syncErrors];
    }
}

#pragma mark -

- (NSString *)version {
    return @"API";
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:API: %p>", [self class], self];
}

@end
