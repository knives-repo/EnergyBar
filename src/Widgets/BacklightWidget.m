//
//  BacklightWidget.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/30/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

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
#import "NSSegmentedControl+Utils.h"

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
    
    [control style];

    self.customizationLabel = @"Keyboard Brightness";
    self.view = control;
    
}

- (void)click:(id)sender
{
    NSSegmentedControl *control = sender;
    switch (control.selectedSegment)
    {
        case 0:
            // brightness down
            [BezelWindow hide];
            PostAuxKeyPress(NX_KEYTYPE_ILLUMINATION_DOWN);
            break;
        case 1:
            // brightness up
            [BezelWindow hide];
            PostAuxKeyPress(NX_KEYTYPE_ILLUMINATION_UP);
            break;
    }
}

@end
