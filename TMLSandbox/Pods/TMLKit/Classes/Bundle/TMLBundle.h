//
//  TMLBundle.h
//  Demo
//
//  Created by Pasha on 11/7/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TMLBundleVersionFilename;
extern NSString * const TMLBundleApplicationFilename;
extern NSString * const TMLBundleSourcesFilename;
extern NSString * const TMLBundleTranslationsFilename;
extern NSString * const TMLBundleTranslationKeysFilename;
extern NSString * const TMLBundleLanguageFilename;
extern NSString * const TMLBundleSourcesRelativePath;

extern NSString * const TMLBundleVersionKey;
extern NSString * const TMLBundleURLKey;

extern NSString * const TMLBundleErrorDomain;
extern NSString * const TMLBundleErrorResourcePathKey;
extern NSString * const TMLBundleErrorsKey;

typedef NS_ENUM(NSInteger, TMLBundleErrorCode) {
    TMLBundleInvalidResourcePath,
    TMLBundleMissingResources
};

@class TMLApplication;

@interface TMLBundle : NSObject

/**
 *  Returns main translation bundle. This bundle contains project definition, including
 *  available languages and translations. This method may return nil if there are no
 *  bundles available locally.
 *
 *  @return Main translation bundle, or nil, if none exist locally.
 */
+ (instancetype)mainBundle;

+ (instancetype)apiBundle;

+ (instancetype)bundleWithVersion:(NSString *)version;

- (instancetype)initWithContentsOfDirectory:(NSString *)path;

- (BOOL)isEqualToBundle:(TMLBundle *)bundle;

/**
 *  Bundle version
 */
@property (readonly, nonatomic) NSString *version;

/**
 *  Absolute path to the bundle on disk
 */
@property (readonly, nonatomic) NSString *path;

/**
 *  Array of languages contained in the bundle
 */
@property (readonly, nonatomic) NSArray *languages;

/**
 *  Array of locales for which there are locally stored translations
 */
@property (readonly, nonatomic) NSArray *availableLocales;

/**
 *  Array of locales supported by the bundle
 */
@property (readonly, nonatomic) NSArray *locales;

/**
 *  List of TMLSource names used in the bundle
 */
@property (readonly, nonatomic) NSArray *sources;

/**
 *  Dictionary of translation keys. These may not be available, as archived bundles do not include them
 */
@property (readonly, nonatomic) NSDictionary *translationKeys;

/**
 *  Application info included in the bundle
 */
@property (readonly, nonatomic) TMLApplication *application;

/**
 *  Source URL from which this bundle was derrived
 */
@property (readonly, nonatomic) NSURL *sourceURL;

@property (readonly, nonatomic) BOOL isMutable;

#pragma mark -
@property (readonly, nonatomic, getter=isValid) BOOL valid;

#pragma mark - Languages

- (TMLLanguage *)languageForLocale:(NSString *)locale;

#pragma mark - Translations

- (BOOL)hasLocaleTranslationsForLocale:(NSString *)locale;

/**
 *  Returns dictionary of TMLTranslation objects, keyed by translation key, for the given locale
 *
 *  @param locale Locale used to search translations
 *
 *  @return Dictionary of TMLTranslation objects, keyed by translation key.
 */
- (NSDictionary *)translationsForLocale:(NSString *)locale;

/**
 *  Loads translations for given locale. This will first check for translation data stored locally.
 *  If that fails, translation data will be loaded from a remote host (CDN or via API).
 *
 *  Upon loading translation data, completion block is called. Error argument passed to that completion block
 *  woudl indicate whether operation was successful or not. If successul, you'll find translations
 *  accessible via @selector(translationsForLocale:) method.
 *
 *  @param aLocale    Locale for translations
 *  @param completion Completion block
 */
- (void)loadTranslationsForLocale:(NSString *)aLocale
                       completion:(void(^)(NSError *error))completion;

#pragma mark - Translation Keys
/**
 *  Returns list of translation keys for translations whose label matches given string in the given locale.
 *
 *  @param string String to match
 *  @param locale Locale for translations
 *
 *  @return List of translation keys
 */
- (NSArray *)translationKeysMatchingString:(NSString *)string
                                    locale:(NSString *)locale;

@end
