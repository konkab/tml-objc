//
//  TMLTranslationKeyTest.m
//  TML
//
//  Created by Michael Berkovich on 1/22/14.
//  Copyright (c) 2014 TMLHub. All rights reserved.
//

#import "TMLAPISerializer.h"
#import "TMLConfiguration.h"
#import "TMLTestBase.h"
#import "TMLTranslationKey.h"

@interface TMLTranslationKeyTest : TMLTestBase

@end

@implementation TMLTranslationKeyTest

- (void) testSubstitution {
    TMLLanguage *en = [self languageForLocale:@"en-US"];
    
    TMLTranslationKey *tk = [[TMLTranslationKey alloc] init];
    tk.locale = @"en-US";
    tk.label = @"Hello World";
    XCTAssertEqualObjects([tk translateToLanguage:en], @"Hello World");

    tk = [[TMLTranslationKey alloc] init];
    tk.locale = @"en-US";
    tk.label = @"[bold: Hello World]";
    XCTAssertEqualObjects([tk translateToLanguage:en
                                           tokens:@{@"bold": @"<b>{$0}</b>"}
                                          options:@{TMLTokenFormatOptionName: TMLHTMLTokenFormatString}],
                          @"<b>Hello World</b>");
}


- (void) testDefaultTokens {
    TMLLanguage *en = [self languageForLocale:@"en-US"];
    
    TMLConfiguration *config = [[TML sharedInstance] configuration];
    [config setDefaultTokenValue:@"<strong>{$0}</strong>" forName:@"indent" type:TMLDecorationTokenType format:TMLHTMLTokenFormat];
    [config setDefaultTokenValue:@"World" forName:@"world" type:TMLDataTokenType];
    
    TMLTranslationKey *tk = [[TMLTranslationKey alloc] init];
    tk.locale = @"en-US";
    tk.label = @"[indent: Hello World]";
    XCTAssertEqualObjects([tk translateToLanguage:en
                                           tokens:nil
                                          options:@{TMLTokenFormatOptionName: TMLHTMLTokenFormatString}],
                          @"<strong>Hello World</strong>");
    
    tk = [[TMLTranslationKey alloc] init];
    tk.locale = @"en-US";
    tk.label = @"[indent: Hello {world}]";
    XCTAssertEqualObjects([tk translateToLanguage:en
                                           tokens:nil
                                          options:@{TMLTokenFormatOptionName: TMLHTMLTokenFormatString}],
                          @"<strong>Hello World</strong>");
}


@end
