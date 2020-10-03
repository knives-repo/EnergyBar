//
//  OutlookUtils.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/29/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OutlookEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface OutlookUtils : NSObject

+ (NSColor*) defaultBusyColor;

+ (void) styleShowAsIndicator:(NSView*) showAsView forEvent:(OutlookEvent*) event;

+ (NSDictionary*) presetColors;
+ (NSArray*) presetColorNames;

@end

NS_ASSUME_NONNULL_END
