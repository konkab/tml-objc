//
//  NSURL+TML.m
//  TMLKit
//
//  Created by Pasha on 12/7/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "NSURL+TML.h"

@implementation NSURL (TML)

- (NSURL *)URLByAppendingQueryParameters:(NSDictionary *)queryParameters {
    NSMutableString *string = [[self absoluteString] mutableCopy];
    if (self.query.length == 0) {
        if ([string hasSuffix:@"?"] == NO) {
            [string appendString:@"?"];
        }
    }
    NSCharacterSet *charSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    for (NSString *key in queryParameters) {
        NSString *queryKey = [key stringByAddingPercentEncodingWithAllowedCharacters:charSet];
        NSString *queryValue = [queryParameters[key] stringByAddingPercentEncodingWithAllowedCharacters:charSet];
        [string appendFormat:@"&%@=%@", queryKey, queryValue];
    }
    return [NSURL URLWithString:[string copy]];
}

@end
