//
//  LevelIndicator.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/26/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "LevelIndicator.h"
#import "BezelWindow.h"
#import "NSColor+Hex.h"

#define MAX_CELLS 16
#define PADDING 1
#define ALPHA 0.60

@implementation LevelIndicator

- (id)initWithFrame:(NSRect) frame {
    
    // check that width is ok
    int width = frame.size.width;
    while ((width - PADDING) % MAX_CELLS != 0) {
        width++;
    }
    
    // do it
    frame.size.width = width;
    self = [super initWithFrame:frame];
    return self;
}

- (void)layout {
    
    // clear
    for (NSView* view in self.subviews) {
        [view removeFromSuperviewWithoutNeedingDisplay];
    }

    // calc cell size
    //  W = p + n*(w+p)
    //  w = (W-p)/n - p
    int width = round((self.frame.size.width - PADDING) / MAX_CELLS) - PADDING;
    int height = (self.frame.size.height - 2 * PADDING);
    
    // indicators
    int x = PADDING;
    int cells = round(MAX_CELLS * self.value);
    for (int i=0; i<cells; i++) {
        
        NSRect rc = NSMakeRect(x, PADDING, width, height);

        if ([BezelWindow isDarkMode]) {

            NSView* view = [[NSView alloc] initWithFrame:rc];
            [view setWantsLayer:YES];
            [view.layer setBackgroundColor:[[NSColor colorFromHex:0x757575] CGColor]];
            [self addSubview:view];

        } else {

            NSVisualEffectView* view = [[NSVisualEffectView alloc] initWithFrame:rc];
            [view setWantsLayer:YES];
            [view setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
            [view setMaterial:NSVisualEffectMaterialLight];
            [view setState:NSVisualEffectStateActive];
            [view.layer setBackgroundColor:[[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] CGColor]];
            [self addSubview:view];
            
        }
       
        x += width + PADDING;
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    
    // fill
    if ([BezelWindow isDarkMode] == NO) {
        [[NSColor blackColor] setFill];
        NSRectFill(dirtyRect);
    }

    // default
    [super drawRect:dirtyRect];

}

@end
