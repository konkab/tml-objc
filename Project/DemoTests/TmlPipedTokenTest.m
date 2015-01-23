//
//  TmlPipedTokenTest.m
//  Tml
//
//  Created by Michael Berkovich on 1/22/14.
//  Copyright (c) 2014 TmlHub. All rights reserved.
//

#import "TmlPipedToken.h"
#import "TmlLanguageContext.h"
#import <Foundation/Foundation.h>
#import "TmlTestBase.h"

@interface TmlPipedTokenTest : TmlTestBase

@end

@implementation TmlPipedTokenTest

/***********************************************************************
 #
 # Piped Token Form
 #
 # {count | message}   - will not include count value: "messages"
 # {count | message, messages}
 # {count:number | message, messages}
 # {user:gender | he, she, he/she}
 # {now:date | did, does, will do}
 # {users:list | all male, all female, mixed genders}
 #
 # {count || message, messages}  - will include count:  "5 messages"
 #
 ***********************************************************************/

- (void) testParsing {
    TmlPipedToken *token;

    token = [[TmlPipedToken alloc] initWithName:@"{count | message}"];
    XCTAssert([@"{count | message}" isEqual: token.fullName]);
    XCTAssert([@"count" isEqual: token.shortName]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"|" isEqual: token.separator]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);

    token = [[TmlPipedToken alloc] initWithName:@"{count| message}"];
    XCTAssert([@"{count| message}" isEqual: token.fullName]);
    XCTAssert([@"count" isEqual: token.shortName]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"|" isEqual: token.separator]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);
    
    token = [[TmlPipedToken alloc] initWithName:@"{count|message}"];
    XCTAssert([@"{count|message}" isEqual: token.fullName]);
    XCTAssert([@"count" isEqual: token.shortName]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"|" isEqual: token.separator]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);
    
    token = [[TmlPipedToken alloc] initWithName:@"{count || message}"];
    XCTAssert([@"{count || message}" isEqual: token.fullName]);
    XCTAssert([@"count" isEqual: token.shortName]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);

    token = [[TmlPipedToken alloc] initWithName:@"{count|| message}"];
    XCTAssert([@"{count|| message}" isEqual: token.fullName]);
    XCTAssert([@"count" isEqual: token.shortName]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);
    
    token = [[TmlPipedToken alloc] initWithName:@"{count||message}"];
    XCTAssert([@"{count||message}" isEqual: token.fullName]);
    XCTAssert([@"count" isEqual: token.shortName]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);

    token = [[TmlPipedToken alloc] initWithName:@"{count:number||message}"];
    XCTAssert([@"{count:number||message}" isEqual: token.fullName]);
    XCTAssert([@"count" isEqual: token.shortName]);
    XCTAssert([@[@"message"] isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[@"number"] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);
    
    token = [[TmlPipedToken alloc] initWithName:@"{count|| message, messages}"];
    XCTAssert([@"{count|| message, messages}" isEqual: token.fullName]);
    XCTAssert([@"count" isEqual: token.shortName]);
    NSArray *expectation = @[@"message", @"messages"];
    XCTAssert([expectation isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);

    token = [[TmlPipedToken alloc] initWithName:@"{count|| one: message, other: messages}"];
    XCTAssert([@"{count|| one: message, other: messages}" isEqual: token.fullName]);
    XCTAssert([@"count" isEqual: token.shortName]);
    expectation = @[@"one: message", @"other: messages"];
    XCTAssert([expectation isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);

    token = [[TmlPipedToken alloc] initWithName:@"{count||one:message,other:messages}"];
    XCTAssert([@"{count||one:message,other:messages}" isEqual: token.fullName]);
    XCTAssert([@"count" isEqual: token.shortName]);
    expectation = @[@"one:message", @"other:messages"];
    XCTAssert([expectation isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);
    
    token = [[TmlPipedToken alloc] initWithName:@"{count:number || one: message, other: messages}"];
    XCTAssert([@"{count:number || one: message, other: messages}" isEqual: token.fullName]);
    XCTAssert([@"count" isEqual: token.shortName]);
    expectation = @[@"one: message", @"other: messages"];
    XCTAssert([expectation isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[@"number"] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);
 
    token = [[TmlPipedToken alloc] initWithName:@"{count : number || one : message, other : messages}"];
    XCTAssert([@"{count : number || one : message, other : messages}" isEqual: token.fullName]);
    XCTAssert([@"count" isEqual: token.shortName]);
    expectation = @[@"one : message", @"other : messages"];
    XCTAssert([expectation isEqual: token.parameters]);
    XCTAssert([@"||" isEqual: token.separator]);
    XCTAssert([@[@"number"] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);

    XCTAssert([token isValueDisplayedInTranslation]);

    token = [[TmlPipedToken alloc] initWithName:@"{user| Born on}"];
    XCTAssert([@"{user| Born on}" isEqual: token.fullName]);
    XCTAssert([@"user" isEqual: token.shortName]);
    XCTAssert([@[@"Born on"] isEqual: token.parameters]);
    XCTAssert([@"|" isEqual: token.separator]);
    XCTAssert([@[] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);

    XCTAssert(![token isValueDisplayedInTranslation]);

    token = [[TmlPipedToken alloc] initWithName:@"{user:gender| Born on}"];
    XCTAssert([@"{user:gender| Born on}" isEqual: token.fullName]);
    XCTAssert([@"user" isEqual: token.shortName]);
    XCTAssert([@[@"Born on"] isEqual: token.parameters]);
    XCTAssert([@"|" isEqual: token.separator]);
    XCTAssert([@[@"gender"] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);

    token = [[TmlPipedToken alloc] initWithName:@"{user:gender | Born on}"];
    XCTAssert([@"{user:gender | Born on}" isEqual: token.fullName]);
    XCTAssert([@"user" isEqual: token.shortName]);
    XCTAssert([@[@"Born on"] isEqual: token.parameters]);
    XCTAssert([@"|" isEqual: token.separator]);
    XCTAssert([@[@"gender"] isEqual: token.contextKeys]);
    XCTAssert([@[] isEqual: token.caseKeys]);
}

- (void) testValueMapForContext {
    TmlPipedToken *token;
    NSDictionary *expectation;
    
    TmlLanguageContext *context = [[TmlLanguageContext alloc] initWithAttributes: [self loadJSON: @"ctx_en-US_gender"]];

    token = [[TmlPipedToken alloc] initWithName:@"{user:gender| other: Born on}"];
    expectation = @{@"other": @"Born on"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
    token = [[TmlPipedToken alloc] initWithName:@"{user| male: He, female: She}"];
    expectation = @{@"male": @"He", @"female": @"She"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TmlPipedToken alloc] initWithName:@"{user| male: He, female: She, other: He/She}"];
    expectation = @{@"male": @"He", @"female": @"She", @"other": @"He/She"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
    token = [[TmlPipedToken alloc] initWithName:@"{user:gender| Born on}"];
    expectation = @{@"other": @"Born on"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
    token = [[TmlPipedToken alloc] initWithName:@"{user| He, She}"];
    expectation = @{@"male": @"He", @"female": @"She", @"other": @"He/She"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TmlPipedToken alloc] initWithName:@"{user| He, She, She/He}"];
    expectation = @{@"male": @"He", @"female": @"She", @"other": @"She/He"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
    context = [[TmlLanguageContext alloc] initWithAttributes: [self loadJSON: @"ctx_en-US_number"]];
    
    token = [[TmlPipedToken alloc] initWithName:@"{count|| one: message, many: messages}"];
    expectation = @{@"one": @"message", @"many": @"messages"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TmlPipedToken alloc] initWithName:@"{count|| message, messages}"];
    expectation = @{@"one": @"message", @"other": @"messages"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
//    token = [[TmlPipedToken alloc] initWithName:@"{count|| message}"];
//    expectation = @{@"one": @"message", @"other": @"messages"};
//    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
    context = [[TmlLanguageContext alloc] initWithAttributes: [self loadJSON: @"ctx_ru_gender"]];
    
    token = [[TmlPipedToken alloc] initWithName:@"{user| female: родилась, other: родился}"];
    expectation = @{@"female": @"родилась", @"other": @"родился"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TmlPipedToken alloc] initWithName:@"{user| родился, родилась}"];
    expectation = @{@"female": @"родилась", @"other": @"родился"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TmlPipedToken alloc] initWithName:@"{user| родился}"];
    expectation = @{@"other": @"родился"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
    context = [[TmlLanguageContext alloc] initWithAttributes: [self loadJSON: @"ctx_ru_number"]];
    
    token = [[TmlPipedToken alloc] initWithName:@"{count|| one: сообщение, few: сообщения, other: сообщений}"];
    expectation = @{@"one": @"сообщение", @"few": @"сообщения", @"other": @"сообщений"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TmlPipedToken alloc] initWithName:@"{count|| сообщение, сообщения, сообщений}"];
    expectation = @{@"one": @"сообщение", @"few": @"сообщения", @"many": @"сообщений", @"other": @"сообщений"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);

    token = [[TmlPipedToken alloc] initWithName:@"{count|| сообщение, сообщения, сообщений, сообщения}"];
    expectation = @{@"one": @"сообщение", @"few": @"сообщения", @"many": @"сообщений", @"other": @"сообщения"};
    XCTAssert([expectation isEqual: [token generateValueMapForContext:context]]);
    
}

@end
