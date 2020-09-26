//
//  NSColor+Hex.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/26/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "NSColor+Hex.h"

#define NSColorFromRGB(rgbValue) [NSColor colorWithCalibratedRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@implementation NSColor (Hex)

+(id)colorFromHex:(int) hex {
    return NSColorFromRGB(hex);
}

@end
