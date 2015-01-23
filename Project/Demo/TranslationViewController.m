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

#import "TranslationViewController.h"
#import "Tml.h"
#import "UIViewController+Tml.h"

@interface TranslationViewController ()

@property (weak, nonatomic) IBOutlet UITextView *originalTextView;

@property (weak, nonatomic) IBOutlet UITextView *translationTextView;

@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

@property (weak, nonatomic) IBOutlet UILabel *originalLabel;

@property (weak, nonatomic) IBOutlet UILabel *translationLabel;

@end

@implementation TranslationViewController

@synthesize label, context, tokens, options;

@synthesize navigationItem;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self translate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSDictionary *) parsedTokens {
    if ([self.tokens length] == 0) {
        return @{};
    }
    
    NSData *jsonData = [self.tokens dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error)
        return [NSDictionary dictionary];
    
    return  result;
}

- (NSDictionary *) parsedOptions {
    if ([self.options length] == 0) {
        return @{};
    }
    
    NSData *jsonData = [self.options dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error)
        return [NSDictionary dictionary];
    
    return  result;
}

- (IBAction)translate:(id)sender {
    self.originalTextView.text = self.label;

    TmlBeginSource(@"samples");
    
    NSObject *translation = TmlLocalizedAttributedStringWithDescriptionAndTokensAndOptions(self.label, self.description, [self parsedTokens], [self parsedOptions]);
    [self setTextValue:translation toField:self.translationTextView];
    
    TmlEndSource
}

- (IBAction)changeLanguage:(id)sender {
    [TmlLanguageSelectorViewController changeLanguageFromController:self];
}

- (IBAction)openTranslator:(id)sender {
    [TmlTranslatorViewController translateFromController:self];
}

- (void) tr8nLanguageSelectorViewController:(TmlLanguageSelectorViewController *) tr8nLanguageSelectorViewController didSelectLanguage: (TmlLanguage *) language {
    [self translate:self];
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
  
    TmlBeginSource(@"Translations");

    NSString *languageName = [[[Tml sharedInstance] currentLanguage] englishName];
    [self setTextValue:TmlLocalizedStringWithTokens(@"{language} Translation", @{@"language": TmlLocalizedString(languageName)}) toField:self.navigationItem];
    [self setTextValue:TmlLocalizedString(@"Original Label") toField:self.originalLabel];
    [self setTextValue:TmlLocalizedString(@"Translation") toField:self.translationLabel];

    TmlEndSource
}

@end
