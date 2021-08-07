//
//  NSImage+Utils.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/30/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImage(Utils)

+ (NSImage*) swatchWithColor:(NSColor*) color size:(NSSize) size;

- (NSImage *) tintedWithColor:(NSColor *)tint;

@end

NS_ASSUME_NONNULL_END
