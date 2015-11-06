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

#import <Foundation/Foundation.h>
#import "TMLLanguage.h"
#import "TMLBase.h"

@interface TMLLanguageCase : TMLBase

// Holds reference back to the language it belongs to
@property(nonatomic, weak) TMLLanguage *language;

// How to apply the case: "phrase" or "words"
@property(nonatomic, strong) NSString *application;

// Unique key identifying the language case
@property(nonatomic, strong) NSString *keyword;

// General name in Latin
@property(nonatomic, strong) NSString *latinName;

// Name in native language
@property(nonatomic, strong) NSString *nativeName;

// Description of the language case
@property(nonatomic, strong) NSString *description;

// List of all rules for the language case
@property(nonatomic, strong) NSArray *rules;

// Finds matching rule for value
- (NSObject *) findMatchingRule: (NSString *) value;

// Finds matching rule for value and object
- (NSObject *) findMatchingRule: (NSString *) value forObject: (NSObject *) object;

// Applies rule for value
- (NSString *) apply: (NSString *) value;

// Applies rule for value based on object properties
- (NSString *) apply: (NSString *) value forObject: (NSObject *) object;

@end