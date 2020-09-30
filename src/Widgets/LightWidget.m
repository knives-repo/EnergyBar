/**
 * @file LightWidget.m
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

#import "LightWidget.h"
#import "KeyEvent.h"
#import "BezelWindow.h"
#import "NSSegmentedControl+Utils.h"

@interface LightWidget() {
    NSInteger activeSegment;
    int lastSlidePosition;
    BOOL modified;
}
@end

@implementation LightWidget

- (void)commonInit
{
    NSPressGestureRecognizer *shortPress = [[[NSPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(shortPressAction:)] autorelease];
    shortPress.allowedTouchTypes = NSTouchTypeMaskDirect;
    shortPress.minimumPressDuration = 0;

    NSSegmentedControl *control = [NSSegmentedControl
        segmentedControlWithImages:[NSArray arrayWithObjects:
            [NSImage imageNamed:@"BrightnessDown"],
            [NSImage imageNamed:@"KeyboardBrightnessUp"],
            nil]
        trackingMode:NSSegmentSwitchTrackingMomentary
        target:nil action:nil];
    control.translatesAutoresizingMaskIntoConstraints = NO;
    control.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    control.tag = 'ctrl';
    
    [control setSegmentsWidth:WIDGET_STANDARD_WIDTH];
    
    [control addGestureRecognizer:shortPress];

    self.customizationLabel = @"Let there be light!";
    self.view = control;
    
}

- (void)shortPressAction:(NSGestureRecognizer *)recognizer
{
    switch (recognizer.state)
    {
    case NSGestureRecognizerStateBegan:
        [self shortPressBegan:recognizer];
        break;
    case NSGestureRecognizerStateChanged:
        [self shortPressChanged:recognizer];
        break;
    case NSGestureRecognizerStateEnded:
    case NSGestureRecognizerStateCancelled:
        [self shortPressEnded:recognizer];
        break;
    default:
        return;
    }
}

- (void)shortPressBegan:(NSGestureRecognizer *)recognizer
{
    // get active segment
    NSPoint point = [recognizer locationInView:self.view];
    activeSegment = [self.view segmentForX:point.x];
    lastSlidePosition = point.x;
    modified = NO;
    
    // hide bezel window
    [BezelWindow hide];
}

- (void)shortPressChanged:(NSGestureRecognizer *)recognizer
{
    // we need an active segment
    if (activeSegment == -1) {
        return;
    }

    // speed this down
    NSPoint point = [recognizer locationInView:self.view];
    int positionDelta = point.x - lastSlidePosition;
    if (abs(positionDelta) < 5) {
        return;
    }
    
    // record new position that triggered a change
    lastSlidePosition = point.x;
    modified = YES;

    // process
    switch (activeSegment)
    {
        case 0:
            if (positionDelta < 0) {
                PostAuxKeyPress(NX_KEYTYPE_BRIGHTNESS_DOWN);
            } else if (positionDelta > 0) {
                PostAuxKeyPress(NX_KEYTYPE_BRIGHTNESS_UP);
            }
            break;
        case 1:
            if (positionDelta < 0) {
                PostAuxKeyPress(NX_KEYTYPE_ILLUMINATION_DOWN);
            } else if (positionDelta > 0) {
                PostAuxKeyPress(NX_KEYTYPE_ILLUMINATION_UP);
            }
            break;
    }
}

- (void)shortPressEnded:(NSGestureRecognizer *)recognizer
{
    // key up
    if (modified == NO) {
        if (activeSegment == 0 || activeSegment == 1) {
            [BezelWindow showWithMessage:@"Slide your finger over the button to adjust brightness"];
        }
    }
    
    // done
    activeSegment = -1;
}

@end
