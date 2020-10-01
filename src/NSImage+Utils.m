//
//  NSImage+Utils.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/30/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "NSImage+Utils.h"

@implementation NSImage(Utils)

- (NSImage *) tintedWithColor:(NSColor *)tint
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
