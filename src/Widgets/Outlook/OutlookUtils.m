//
//  OutlookUtils.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/29/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import "OutlookUtils.h"
#import "NSColor+Hex.h"

@implementation OutlookUtils

+ (NSColor*) defaultBusyColor
{
    return [NSColor colorFromHex:0x0078d4];
}

+ (void) styleShowAsIndicator:(NSView*) showAsView forEvent:(OutlookEvent*) event
{
    // reset border
    [showAsView.layer setBorderWidth:0];
    
    // depends on event status
    switch (event.showAs) {
        case ShowAsUnknown:
            [showAsView.layer setBackgroundColor:[[NSColor grayColor] CGColor]];
            break;
        case ShowAsFree:
            [showAsView.layer setBackgroundColor:[[NSColor clearColor] CGColor]];
            [showAsView.layer setBorderColor:[[NSColor whiteColor] CGColor]];
            [showAsView.layer setBorderWidth:1];
            break;
        case ShowAsTentative:
            [showAsView.layer setBackgroundColor:[[NSColor colorFromHex:0x7fb2ee] CGColor]];
            break;
        case ShowAsBusy:
            [showAsView.layer setBackgroundColor:[[OutlookUtils colorForBusyEvent:event] CGColor]];
            break;
        case ShowAsOutOfOffice:
            [showAsView.layer setBackgroundColor:[[NSColor purpleColor] CGColor]];
            break;
    }

}

+ (NSColor*) colorForBusyEvent:(OutlookEvent*) event
{
    // importance
    if (event.importance == ImportanceHigh) {
        return [[OutlookUtils presetColors] objectForKey:@"preset15"];
    }

    // load
    NSArray* categories = [[NSUserDefaults standardUserDefaults] arrayForKey:@"outlookCategories"];
    NSDictionary* presetColors = [OutlookUtils presetColors];

    // default
    if (categories != nil && event.categories != nil && event.categories.count > 0) {

        // 1st category
        NSString* category = [event.categories firstObject];
        
        // iterate
        for (NSDictionary* categoryDefinition in categories) {
            if ([[categoryDefinition objectForKey:@"name"] isEqualToString:category]) {
                NSString* color = [categoryDefinition objectForKey:@"color"];
                if ([[presetColors allKeys] containsObject:color]) {
                    return [presetColors objectForKey:color];
                }
            }
        }

    }
    
    // default
    return [OutlookUtils defaultBusyColor];

}

+ (NSDictionary*) presetColors {
    
    //
    // TODO
    // https://docs.microsoft.com/en-us/graph/api/resources/outlookcategory?view=graph-rest-1.0
    //
    return @{
        @"preset0": [NSColor colorFromHex:0xe19b9a],    // Red
        @"preset1": [NSColor colorFromHex:0xf5ad6c],    // Orange
        @"preset2": [NSColor colorFromHex:0xeed27a],    // Brown
        @"preset3": [NSColor colorFromHex:0xf8f175],    // Yellow
        @"preset4": [NSColor colorFromHex:0x8cd480],    // Green
        @"preset5": [NSColor colorFromHex:0x85d1be],    // Teal
        @"preset6": [NSColor colorFromHex:0xb8c69e],    // Olive
        @"preset7": [NSColor colorFromHex:0x86abe7],    // Blue
        @"preset8": [NSColor colorFromHex:0xa391d9],    // Purple
        @"preset9": [NSColor colorFromHex:0xd79fb8],    // Cranberry
        @"preset10": [NSColor colorFromHex:0xcbcacd],   // Steel
        @"preset11": [NSColor colorFromHex:0x66748f],   // DarkSteel
        @"preset12": [NSColor colorFromHex:0xb1b1b1],   // Gray
        @"preset13": [NSColor colorFromHex:0x676968],   // DarkGray
        @"preset14": [NSColor colorFromHex:0x4e4e4e],   // Black
        @"preset15": [NSColor colorFromHex:0xb21d1a],   // DarkRed
        @"preset16": [NSColor colorFromHex:0xd86600],   // DarkOrange
        @"preset17": [NSColor colorFromHex:0xbb901c],   // DarkBrown
        @"preset18": [NSColor colorFromHex:0xada900],   // DarkYellow
        @"preset19": [NSColor colorFromHex:0x277a1e],   // DarkGreen
        @"preset20": [NSColor colorFromHex:0x278a71],   // DarkTeal
        @"preset21": [NSColor colorFromHex:0x718438],   // DarkOlive
        @"preset22": [NSColor colorFromHex:0x1d5799],   // DarkBlue
        @"preset23": [NSColor colorFromHex:0x5e439c],   // DarkPurple
        @"preset24": [NSColor colorFromHex:0x8e4669],   // DarkCranberry
    };

}

+ (NSArray*) presetColorNames
{
    return [[[OutlookUtils presetColors] allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        int num1 = [[obj1 stringByReplacingOccurrencesOfString:@"preset" withString:@""] intValue];
        int num2 = [[obj2 stringByReplacingOccurrencesOfString:@"preset" withString:@""] intValue];
        if (num1 < num2) return NSOrderedAscending;
        if (num1 > num2) return NSOrderedDescending;
        return NSOrderedSame;
    }];

}

@end
