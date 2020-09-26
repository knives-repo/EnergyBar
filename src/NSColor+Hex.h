//
//  NSColor+Hex.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/26/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSColor (Hex)
+(id)colorFromHex:(int) hex;
@end

NS_ASSUME_NONNULL_END
