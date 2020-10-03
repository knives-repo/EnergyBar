//
//  NSImage+Utils.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/30/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "NSImage+Utils.h"

@implementation NSImage(Utils)

+ (NSImage*) swatchWithColor:(NSColor*) color size:(NSSize) size
{
    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    [color set];
    NSRectFill(NSMakeRect(0, 0, size.width, size.height));
    [image unlockFocus];
    return image;
}

- (NSImage*) tintedWithColor:(NSColor*) tint
{
    [self setTemplate:NO];
    NSImage *image = [[self copy] autorelease];
    if (tint) {
        [image lockFocus];
        [tint set];
        NSRect imageRect = {NSZeroPoint, [image size]};
        NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceIn);
        [image unlockFocus];
    }
    return image;
}

@end
