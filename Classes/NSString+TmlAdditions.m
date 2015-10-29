//
//  NSString+TmlAdditions.m
//  Demo
//
//  Created by Pasha on 10/29/15.
//  Copyright © 2015 TmlHub Inc. All rights reserved.
//

#import "NSString+TmlAdditions.h"
#import "Tml.h"

@implementation NSString (TmlAdditions)

- (NSString *)tmlTranslationBundleVersionFromPath {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"tml_([0-9]+)\\.zip"
                                                                                     options:NSRegularExpressionCaseInsensitive
                                                                                       error:&error];
    if (error != nil) {
        TmlError(@"Error constructing regexp for determinging version of local localization bundles: %@", error);
        return nil;
    }
    
    NSString *version = [regex stringByReplacingMatchesInString:self
                                                        options:NSMatchingReportCompletion
                                                          range:NSMakeRange(0, self.length)
                                                   withTemplate:@"$1"];
    return version;
}

@end
