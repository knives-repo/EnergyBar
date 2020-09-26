//
//  ControlWidgetLevelView.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/25/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "ControlWidgetLevelView.h"

@implementation ControlWidgetLevelView
{
    double _value;
    CGFloat _indicatorWidth;
}

@synthesize tag;

- (void)drawRect:(NSRect)rect
{
    NSColor *backgroundColor = self.backgroundColor;
    NSColor *foregroundColor = self.foregroundColor;

    if (nil == backgroundColor)
        backgroundColor = [NSColor clearColor];
    if (nil == foregroundColor)
    {
        if (@available(macOS 10.14, *))
            foregroundColor = [NSColor controlAccentColor];
        else
            foregroundColor = [NSColor systemBlueColor];
    }

    rect = self.bounds;

    [backgroundColor setFill];
    NSRectFillUsingOperation(rect, NSCompositingOperationSourceOver);

    CGFloat inset = self.inset;
    rect = NSInsetRect(rect, inset, inset);

    CGFloat indicatorWidth = self.indicatorWidth;
    if (0 > indicatorWidth)
    {
        CGFloat maxX = NSMaxX(rect);
        indicatorWidth = -indicatorWidth;
        rect.size.width = MIN(indicatorWidth, rect.size.width);
        rect.origin.x = maxX - rect.size.width;
    }
    else if (0 < indicatorWidth)
        rect.size.width = MIN(indicatorWidth, rect.size.width);

    [foregroundColor set];
    CGFloat level = self.value;
    CGFloat x = rect.origin.x + level * rect.size.width;
    CGFloat y = rect.origin.y + level * rect.size.height;
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:rect.origin];
    [path lineToPoint:NSMakePoint(x, NSMinY(rect))];
    [path lineToPoint:NSMakePoint(x, y)];
    [path closePath];
    [path fill];
}

- (double)value
{
    return _value;
}

- (void)setValue:(double)value
{
    if (_value == value)
        return;

    _value = value;
    [self setNeedsDisplay:YES];
}

- (CGFloat)indicatorWidth
{
    return _indicatorWidth;
}

- (void)setIndicatorWidth:(CGFloat)value
{
    if (_indicatorWidth == value)
        return;

    _indicatorWidth = value;
    [self setNeedsDisplay:YES];
}

@end
