/**
 * @file BacklightWidget.m
 *
 * @copyright 2018-2019 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import "BacklightWidget.h"
#import "Brightness.h"
#import "BezelWindow.h"
#import "KeyEvent.h"

@implementation BacklightWidget

- (void)commonInit
{
    NSSegmentedControl *control = [NSSegmentedControl
                                   segmentedControlWithImages:[NSArray arrayWithObjects:
                                                               [NSImage imageNamed:@"KeyboardBrightnessDown"],
                                                               [NSImage imageNamed:@"KeyboardBrightnessUp"],
                                                               nil]
                                   trackingMode:NSSegmentSwitchTrackingMomentary
                                   target:self
                                   action:@selector(click:)];
    control.translatesAutoresizingMaskIntoConstraints = NO;
    control.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    control.tag = 'ctrl';
    
    for (int i=0; i<control.segmentCount; i++) {
        [control setWidth:WIDGET_STANDARD_WIDTH forSegment:i];
    }
    
    self.customizationLabel = @"Backlight";
    self.view = control;
    
}

- (void)click:(id)sender
{
    NSSegmentedControl *control = sender;
    switch (control.selectedSegment)
    {
        case 0:
            // brightness down
            PostAuxKeyPress(NX_KEYTYPE_ILLUMINATION_DOWN);
            break;
        case 1:
            // brightness up
            PostAuxKeyPress(NX_KEYTYPE_ILLUMINATION_UP);
            break;
    }
}

@end
