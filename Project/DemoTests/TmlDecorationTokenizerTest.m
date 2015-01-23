//
//  TmlDecorationTokenizerTest.m
//  Tml
//
//  Created by Michael Berkovich on 1/22/14.
//  Copyright (c) 2014 TmlHub. All rights reserved.
//

#import  "TmlDecorationTokenizer.h"
#import <Foundation/Foundation.h>
#import "TmlTestBase.h"

@interface TmlDecorationTokenizerTest : TmlTestBase

@end

@implementation TmlDecorationTokenizerTest

- (void) testParsing {
    TmlDecorationTokenizer *tdt;
    NSArray *expectation;
    
    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"Hello World"];
    expectation = @[@"[tr8n]", @"Hello World", @"[/tr8n]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tr8n", @"Hello World"];
    XCTAssert([tdt.expression isEqual:expectation]);
    
    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"[bold: Hello World]"];
    expectation = @[@"[tr8n]", @"[bold:", @" Hello World", @"]", @"[/tr8n]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tr8n", @[@"bold", @"Hello World"]];
    XCTAssert([tdt.expression isEqual:expectation]);

    // broken
    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"[bold: Hello World"];
    expectation = @[@"[tr8n]", @"[bold:", @" Hello World", @"[/tr8n]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tr8n", @[@"bold", @"Hello World"]];
    XCTAssert([tdt.expression isEqual:expectation]);

    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"[bold: Hello [strong: World]]"];
    expectation = @[@"[tr8n]", @"[bold:", @" Hello ", @"[strong:", @" World", @"]", @"]", @"[/tr8n]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tr8n", @[@"bold", @"Hello ", @[@"strong", @"World"]]];
    XCTAssert([tdt.expression isEqual:expectation]);

    // broken
    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"[bold: Hello [strong: World]"];
    expectation = @[@"[tr8n]", @"[bold:", @" Hello ", @"[strong:", @" World", @"]", @"[/tr8n]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tr8n", @[@"bold", @"Hello ", @[@"strong", @"World"]]];
    XCTAssert([tdt.expression isEqual:expectation]);
    
    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"[bold1: Hello [strong22: World]]"];
    expectation = @[@"[tr8n]", @"[bold1:", @" Hello ", @"[strong22:", @" World", @"]", @"]", @"[/tr8n]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tr8n", @[@"bold1", @"Hello ", @[@"strong22", @"World"]]];
    XCTAssert([tdt.expression isEqual:expectation]);
    
    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"[bold: Hello, [strong: how] [weak: are] you?]"];
    expectation = @[@"[tr8n]", @"[bold:", @" Hello, ", @"[strong:", @" how", @"]", @" ", @"[weak:", @" are", @"]", @" you?", @"]", @"[/tr8n]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tr8n", @[@"bold", @"Hello, ", @[@"strong", @"how"], @" ", @[@"weak", @"are"], @" you?"]];
    XCTAssert([tdt.expression isEqual:expectation]);

    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"[bold: Hello, [strong: how [weak: are] you?]"];
    expectation = @[@"[tr8n]", @"[bold:", @" Hello, ", @"[strong:", @" how ", @"[weak:", @" are", @"]", @" you?", @"]", @"[/tr8n]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tr8n", @[@"bold", @"Hello, ", @[@"strong", @"how ", @[@"weak", @"are"], @" you?"]]];
    XCTAssert([tdt.expression isEqual:expectation]);

    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"[link: you have [italic: [bold: {count}] messages] [light: in your mailbox]]"];
    expectation = @[@"[tr8n]", @"[link:", @" you have ", @"[italic:", @" ", @"[bold:", @" {count}", @"]", @" messages", @"]", @" ", @"[light:", @" in your mailbox", @"]", @"]", @"[/tr8n]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tr8n", @[@"link", @"you have ", @[@"italic", @"", @[@"bold", @"{count}"], @" messages"], @" ", @[@"light", @"in your mailbox"]]];
    XCTAssert([tdt.expression isEqual:expectation]);

    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"[link] you have [italic: [bold: {count}] messages] [light: in your mailbox] [/link]"];
    expectation = @[@"[tr8n]", @"[link]", @" you have ", @"[italic:", @" ", @"[bold:", @" {count}", @"]", @" messages", @"]", @" ", @"[light:", @" in your mailbox", @"]", @" ", @"[/link]", @"[/tr8n]"];
    XCTAssert([tdt.fragments isEqual:expectation]);
    expectation = @[@"tr8n", @[@"link", @" you have ",@[@"italic", @"", @[@"bold", @"{count}"], @" messages"], @" ", @[@"light", @"in your mailbox"], @" "]];
//    TmlDebug(@"%@", result);
    XCTAssert([tdt.expression isEqual:expectation]);
}

- (void) testEvaluating {
    TmlDecorationTokenizer *tdt;
    NSObject *result;
    NSString *expectation;
    
    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"Hello World"];
    expectation = @"Hello World";
    result = [tdt substituteTokensInLabelUsingData:@{}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[] isEqual:tdt.tokenNames]);

    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"[bold: Hello World]"];
    expectation = @"Hello World";
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @"<strong>{$0}</strong>"}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[@"bold"] isEqual:tdt.tokenNames]);

    expectation = @"Hello World";
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": ^(NSString *value) {
        return [NSString stringWithFormat:@"<b>%@</b>", value];
    }}];
    XCTAssert([result isEqual:expectation]);
    XCTAssert([@[@"bold"] isEqual:tdt.tokenNames]);

    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"[bold: Hello [italic: World]]"];
    expectation = @"Hello World";
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @"<b>{$0}</b>",
                                                     @"italic": ^(NSString *value) {
        return [NSString stringWithFormat:@"<i>%@</i>", value];
    }}];
    XCTAssert([result isEqual:expectation]);
    NSArray *tokens = @[@"bold", @"italic"];
    XCTAssert([tokens isEqual:tdt.tokenNames]);

    tdt = [[TmlDecorationTokenizer alloc] initWithLabel: @"[bold]Hello [italic: World][/bold]"];
    expectation = @"Hello World";
    result = [tdt substituteTokensInLabelUsingData:@{@"bold": @"<b>{$0}</b>",
                                                     @"italic": ^(NSString *value) {
        return [NSString stringWithFormat:@"<i>%@</i>", value];
    }}];
    XCTAssert([result isEqual:expectation]);
    tokens = @[@"bold", @"italic"];
    XCTAssert([tokens isEqual:tdt.tokenNames]);
    
}

@end
