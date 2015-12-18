//
//  UIResponder+TML.m
//  TMLKit
//
//  Created by Pasha on 12/10/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "NSAttributedString+TML.h"
#import "NSObject+TML.h"
#import "TML.h"
#import "TMLTranslationKey.h"
#import "UIResponder+TML.h"
#import "TMLTranslation.h"

@implementation UIResponder (TML)

- (NSDictionary *)tmlTranslationKeysAndPaths {
    NSMutableDictionary *translationKeys = [NSMutableDictionary dictionary];
    NSSet *keyPaths = [self tmlLocalizableKeyPaths];
    for (NSString *keyPath in keyPaths) {
        NSString *translationKey = [self tmlTranslationKeyForKeyPath:keyPath];
        if (translationKey != nil) {
            translationKeys[keyPath] = translationKey;
        }
    }
    return [translationKeys copy];
}

- (NSString *)tmlTranslationKeyForKeyPath:(NSString *)keyPath {
    NSMutableArray *translationKeys = [NSMutableArray array];
    // first lookup the key in the registry
    NSDictionary *registry = [self tmlRegistry];
    NSDictionary *payload = registry[keyPath];
    TMLTranslationKey *translationKey = payload[TMLRegistryTranslationKeyName];
    if (translationKey != nil) {
        [translationKeys addObject:translationKey.key];
    }
    // if nothing in the registry, lookup translation key by localized string
    else {
        NSMutableArray *labelsToMatch = [NSMutableArray array];
        id label = [self valueForKeyPath:keyPath];
        if ([label isKindOfClass:[NSAttributedString class]] == YES) {
            [labelsToMatch addObject:[label tmlAttributedString:nil]];
            [labelsToMatch addObject:[(NSAttributedString *)label string]];
        }
        else if ([label isKindOfClass:[NSString class]] == YES) {
            [labelsToMatch addObject:label];
        }
        
        NSMutableArray *localesToCheck = [NSMutableArray array];
        NSString *currentLocale = [TML currentLocale];
        if (currentLocale != nil) {
            [localesToCheck addObject:currentLocale];
        }
        NSString *defaultLocale = [TML defaultLocale];
        if (defaultLocale != nil && [defaultLocale isEqualToString:currentLocale] == NO) {
            [localesToCheck addObject:defaultLocale];
        }
        
        NSArray *matchingKeys = nil;
        TML *tml = [TML sharedInstance];
        for (NSString *searchLabel in labelsToMatch) {
            for (NSString *locale in localesToCheck) {
                matchingKeys = [tml translationKeysMatchingString:searchLabel
                                                           locale:locale];
                
                if (matchingKeys.count > 1) {
                    NSString *currentLocale = [TML currentLocale];
                    NSString *guessedKey = nil;
                    for (NSString *key in matchingKeys) {
                        NSArray *translations = [tml translationsForKey:key locale:currentLocale];
                        if (translations.count > 0) {
                            for (TMLTranslation *translation in translations) {
                                NSString *label = translation.label;
                                if ([labelsToMatch containsObject:label] == YES) {
                                    guessedKey = key;
                                    break;
                                }
                            }
                        }
                        else if (translationKey == nil) {
                            guessedKey = key;
                        }
                    }
                    if (guessedKey != nil) {
                        matchingKeys = @[guessedKey];
                    }
                }
                
                if (matchingKeys.count > 0) {
                    [translationKeys addObjectsFromArray:matchingKeys];
                    break;
                }
            }
        }
    }
    return [translationKeys firstObject];
}

@end
