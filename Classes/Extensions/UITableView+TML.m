//
//  UITableView+TML.m
//  TMLKit
//
//  Created by Pasha on 12/7/15.
//  Copyright © 2015 Translation Exchange. All rights reserved.
//

#import "UITableView+TML.h"
#import "NSObject+TML.h"

@implementation UITableView (TML)

- (void)restoreTMLLocalizations {
    [super restoreTMLLocalizations];
    [self reloadData];
}

- (void)localizeWithTML {
    [super localizeWithTML];
    NSInteger sections = self.numberOfSections;
    for (NSInteger s=0; s<sections; s++) {
        UIView *headerView = [self headerViewForSection:s];
        [headerView localizeWithTML];
    }
}

@end
