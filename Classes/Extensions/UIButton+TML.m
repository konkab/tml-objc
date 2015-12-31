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
#import "TMLBundle.h"
#import "TMLLanguage.h"
#import "TMLTranslationKey.h"
#import "UIButton+TML.h"

@implementation UIButton (TML)

- (NSArray *)tmlLocalizableStates {
    static NSArray *states;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        states = @[
                   @(UIControlStateNormal),
                   @(UIControlStateHighlighted),
                   @(UIControlStateDisabled),
                   @(UIControlStateSelected),
                   @(UIControlStateApplication)
                   ];
    });
    return states;
}

- (void)restoreTMLLocalizations {
    [super restoreTMLLocalizations];
    UILabel *titleLabel = self.titleLabel;
    if (titleLabel != nil && titleLabel.hidden == NO) {
        NSArray *states = [self tmlLocalizableStates];
        for (NSNumber *stateNumber in states) {
            UIControlState state = [stateNumber integerValue];
            id currentValue = [self attributedTitleForState:state];
            if (currentValue == nil) {
                currentValue = [self titleForState:state];
            }
            NSDictionary *tmlInfo = [currentValue tmlInfo];
            if (tmlInfo.count == 0) {
                continue;
            }
            TMLTranslationKey *translationKey = tmlInfo[TMLRegistryTranslationKeyName];
            NSDictionary *tokens = tmlInfo[TMLRegistryTokensKeyName];
            NSDictionary *options = tmlInfo[TMLRegistryOptionsKeyName];
            id result = [[TML currentLanguage] translate:translationKey.label
                                             description:translationKey.keyDescription
                                                  tokens:tokens
                                                 options:options];
            if (result == nil) {
                result = [[TML defaultLanguage] translate:translationKey.label
                                              description:translationKey.keyDescription
                                                   tokens:tokens
                                                  options:options];
            }
            if (result != nil) {
                if ([result isKindOfClass:[NSAttributedString class]] == YES) {
                    [self setAttributedTitle:result forState:state];
                }
                else {
                    [self setTitle:result forState:state];
                }
            }
        }
    }
}

- (void)localizeWithTML {
    [super localizeWithTML];
    NSArray *states = [self tmlLocalizableStates];
    
    for (NSNumber *state in states) {
        UIControlState controlState = [state integerValue];
        NSAttributedString *attributedTitle = [self attributedTitleForState:controlState];
        NSString *tmlString = nil;
        NSDictionary *tokens = nil;
        if (attributedTitle.length > 0) {
            if (controlState == UIControlStateNormal
                || [attributedTitle isEqualToAttributedString:[self attributedTitleForState:UIControlStateNormal]] == NO) {
                tmlString = [attributedTitle tmlAttributedString:&tokens];
                NSAttributedString *localizedString = TMLLocalizedAttributedString(tmlString, tokens);
                [self setAttributedTitle:localizedString forState:[state integerValue]];
            }
        }
        else {
            NSString *title = [self titleForState:controlState];
            if (controlState == UIControlStateNormal
                || [title isEqualToString:[self titleForState:UIControlStateNormal]] == NO) {
                tmlString = title;
                NSString *localizedString = TMLLocalizedString(tmlString);
                [self setTitle:localizedString forState:[state integerValue]];
            }
        }
    }
}


@end
