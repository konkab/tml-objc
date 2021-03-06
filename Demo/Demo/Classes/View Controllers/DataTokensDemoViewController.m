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

#import "DataTokensDemoViewController.h"
#import "User.h"

@interface DataTokensDemoViewController ()

@end

@implementation DataTokensDemoViewController

- (void) prepareSamples {
    self.items = @[
       @{
           @"title": @"Simple Data Tokens",
           @"items": @[
                   @{
                       @"tml": @"Hello {user}",
                       @"tokens": @{@"user": @"Michael"}
                    },
                   @{
                       @"tml": @"You have selected {language_name} language",
                       @"tokens": @{
                               @"language_name": [TMLCurrentLanguage() englishName]
                        },
                       },
                   @{
                       @"tml": @"Number of messages: {count}",
                       @"tokens": @{@"count": @5}
                    },
                   ]
           },
       @{
           @"title": @"Method Tokens",
           @"items": @[
                   @{
                       @"tml": @"Hello {user.fullName}, you are a {user.gender}",
                       @"tokens": @{@"user": [[[TML sharedInstance] configuration] defaultTokenValueForName:TMLViewingUserTokenName]},
                       @"tokens_desc": @"{\"user\": michael}"
                    },
                ]
           },
       @{
           @"title": @"Piped Tokens",
           @"items": @[
               @{
                   @"tml": @"You have {count||message}",
                   @"tokens": @{@"count": @1}
                   },
               @{
                   @"tml": @"You have {count||message}",
                   @"tokens": @{@"count": @3}
                   },
               @{
                   @"tml": @"You have {count| one message, #count# messages}",
                   @"tokens": @{@"count": @1}
                },
               @{
                   @"tml": @"You have {count| one message, #count# messages}",
                   @"tokens": @{@"count": @2}
                },
               @{
                   @"tml": @"{user| He, She} likes this movie.",
                   @"tokens": @{@"user": @{@"gender": @"male"}},
                },
               @{
                   @"tml": @"{user} uploaded {count|| photo} to {user| his, her} photo album.",
                   @"tokens": @{
                       @"user": @{@"object": @{@"gender": @"male", @"name": @"Michael"}, @"property": @"name"},
                       @"count": @2
                }
             }
            ]
           },
       ];
}

@end
