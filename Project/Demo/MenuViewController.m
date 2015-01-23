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

#import "MenuViewController.h"
#import "Tml.h"
#import "TmlTranslatorViewController.h"
#import "TmlLanguageSelectorViewController.h"
#import "UIViewController+Tml.h"

@interface MenuViewController ()

@property (weak, nonatomic) IBOutlet UITableView *menuTableView;

@end

@implementation MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.items = @[
                   @{
                       @"title": @"",
                       @"items": @[
                               @{
                                   @"title":@"Welcome",
                                   @"controller": @"WelcomeViewController"
                                   },
                               @{
                                   @"title": @"Data Tokens Demo",
                                   @"controller": @"DataTokensDemoViewController"
                                   },
                               @{
                                   @"title": @"Decoration Tokens Demo",
                                   @"controller": @"DecorationTokensDemoViewController"
                                   },
                               @{
                                   @"title": @"Combined Tokens Demo",
                                   @"controller": @"CombinedTokensDemoViewController"
                                   },
                               @{
                                   @"title": @"TML Interactive Console",
                                   @"controller": @"TMLConsoleViewController"
                                   },
                               ]
                       },
                   @{
                       @"title": @"User Interface",
                       @"items": @[
                               @{
                                   @"title": @"Static Form",
                                   @"controller": @"StaticViewController"
                                   },
                               @{
                                   @"title": @"Static Table",
                                   @"controller": @"StaticTableNavigationViewController"
                                   },
                               ]
                       },
                   @{
                       @"title": @"Language Tools",
                       @"items": @[
                               @{
                                   @"title": @"Change Language",
                                   },
                               @{
                                   @"title": @"In-App Translations",
                                   },
                               @{
                                   @"title": @"Translator Tools",
                                   },
                               ]
                       },
                   ];
}

- (void) localize {
    TmlLocalizeViewWithLabel(self.titleLabel, @"Main Menu");
}

- (NSString *) tr8nSourceKey {
    return @"Menu options";
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *sectionHeader = [[UIView alloc] init];
    sectionHeader.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, tableView.frame.size.width, 40)];
    NSDictionary *sec = (NSDictionary *) [self.items objectAtIndex:section];
    TmlLocalizeViewWithLabel(label, [sec objectForKey:@"title"]);
    [sectionHeader addSubview:label];
    return sectionHeader;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCell"];
    }
    
    NSDictionary *section = (NSDictionary *) [self.items objectAtIndex:indexPath.section];
    NSString *title = [[[section objectForKey:@"items"] objectAtIndex:indexPath.row] objectForKey:@"title"];
    TmlLocalizeViewWithLabel(cell.textLabel, title);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            [TmlLanguageSelectorViewController changeLanguageFromController:self];
        } else if (indexPath.row == 1) {
            [TmlTranslatorViewController toggleInAppTranslationsFromController:self];
        } else if (indexPath.row == 2) {
            [TmlTranslatorViewController translateFromController:self];
        }
        return;
    }
    
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

@end
