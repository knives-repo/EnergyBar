//
//  ControlWidgetView.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/25/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "ControlWidgetView.h"

@implementation ControlWidgetView

- (NSSize)intrinsicContentSize
{
    return [[self.subviews firstObject] intrinsicContentSize];
}

- (void)resizeSubviewsWithOldSize:(NSSize)size
{
    NSView *view = [self.subviews lastObject];
    NSRect rect = view.frame;
    rect.origin.y = (self.bounds.size.height - rect.size.height) / 2;
    view.frame = rect;
}

@end
