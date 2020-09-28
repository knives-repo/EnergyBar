//
//  NSSegmentedControl+Utils.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/28/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "NSSegmentedControl+Utils.h"

@implementation NSSegmentedControl(Utils)

- (void)setSegmentsWidth:(int)w {
    for (int i=0; i<self.segmentCount; i++) {
        [self setWidth:w forSegment:i];
    }
}

- (NSInteger)segmentForX:(CGFloat)x
{
    /* HACK:
     * There does not appear to be a direct way to determine the segment from a point.
     *
     * One would think that the -[NSSegmentedControl widthForSegment:] method on the
     * first segment (which happens to be the Play/Pause button) would do the trick.
     * Unfortunately this method returns 0 for automatically sized segments. Arrrrr!
     *
     * So I am adapting here some code that I wrote a long time for "DarwinKit"...
     */
    NSSegmentedControl *control = self;
    NSRect rect = control.bounds;
    CGFloat widths[16] = { 0 }, totalWidth = 0;
    NSInteger count = control.segmentCount, zeroWidthCells = 0;
    for (NSInteger i = 0; count > i; i++)
    {
        widths[i] = [control widthForSegment:i];
        if (0 == widths[i])
            zeroWidthCells++;
        else
            totalWidth += widths[i];
    }
    if (0 < zeroWidthCells)
    {
        totalWidth = rect.size.width - totalWidth;
        for (NSInteger i = 0; count > i; i++)
            if (0 == widths[i])
                widths[i] = totalWidth / zeroWidthCells;
    }
    else
    {
        if (2 <= count)
        {
            CGFloat remWidth = rect.size.width - totalWidth;
            widths[0] += remWidth / 2;
            widths[count - 1] += remWidth / 2;
        }
        else if (1 <= count)
        {
            CGFloat remWidth = rect.size.width - totalWidth;
            widths[0] += remWidth;
        }
    }

    /* now that we have the widths go ahead and figure out which segment has X */
    totalWidth = 0;
    for (NSInteger i = 0; count > i; i++)
    {
        if (totalWidth <= x && x < totalWidth + widths[i])
            return i;

        totalWidth += widths[i];
    }

    return -1;
}

@end
