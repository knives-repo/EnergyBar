//
//  OutlookUtils.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/29/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "OutlookUtils.h"
#import "NSColor+Hex.h"

@implementation OutlookUtils

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
    if (event.importance == ImportanceHigh || (event.categories != nil && [event.categories containsObject:@"Important"])) {
        return [NSColor redColor];
    }
    
    // default
    /*if (self.categories != nil && event.categories != nil && event.categories.count > 0) {

        // 1st category
        NSString* category = [event.categories firstObject];
        
        // iterate
        for (NSDictionary* categoryDefinition in self.categories) {
            if ([[categoryDefinition objectForKey:@"displayName"] isEqualToString:category]) {
                NSString* color = [categoryDefinition objectForKey:@"color"];
                NSDictionary* presetColors = [Outlook presetColors];
                if ([[presetColors allKeys] containsObject:color]) {
                    return [presetColors objectForKey:color];
                }
            }
        }

    }*/
    
    // default
    return [NSColor colorFromHex:0x0078d4];

}

@end
