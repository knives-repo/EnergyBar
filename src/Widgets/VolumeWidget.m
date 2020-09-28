/**
 * @file VolumeWidget.m
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

#import "VolumeWidget.h"
#import "AudioControl.h"
#import "BezelWindow.h"
#import "KeyEvent.h"
#import "NSSegmentedControl+Utils.h"

#define VolumeAdjustIncrement					 (1.0/16.0)

@interface VolumeWidget() {
    NSInteger activeSegment;
    NSTimer* repeatTimer;
    BOOL triggered;
}

@end

@implementation VolumeWidget

- (void)commonInit
{

    NSPressGestureRecognizer *shortPress = [[[NSPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(shortPressAction:)] autorelease];
    shortPress.allowedTouchTypes = NSTouchTypeMaskDirect;
    shortPress.minimumPressDuration = 0;

    NSSegmentedControl *control = [NSSegmentedControl
        segmentedControlWithImages:[NSArray arrayWithObjects:
            [NSImage imageNamed:NSImageNameTouchBarAudioOutputVolumeLowTemplate],
            [NSImage imageNamed:NSImageNameTouchBarAudioOutputVolumeHighTemplate],
            [self volumeMuteImage],
            nil]
        trackingMode:NSSegmentSwitchTrackingMomentary
        target:nil action:nil];
    control.translatesAutoresizingMaskIntoConstraints = NO;
    control.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    control.tag = 'ctrl';
    
    [control setSegmentsWidth:WIDGET_STANDARD_WIDTH];

    [control addGestureRecognizer:shortPress];

    self.customizationLabel = @"Volume";
    self.view = control;
    
    [AudioControl sharedInstanceOutput];
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self];
    
    [super dealloc];
}

- (void)viewWillAppear
{
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(audioControlNotification:)
     name:AudioControlNotification
     object:nil];
}

- (void)viewDidDisappear
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self];
}

- (NSImage *)volumeMuteImage
{
    BOOL mute = [AudioControl sharedInstanceOutput].mute;
    return [NSImage imageNamed:mute ? @"VolumeMuteOn" : @"VolumeMuteOff"];
}

- (void)audioControlNotification:(NSNotification *)notification
{
    [self.view setImage:[self volumeMuteImage] forSegment:2];
}

- (void)adjustVolumeBy:(double)delta {
    double vol = [AudioControl sharedInstanceOutput].volume;
    vol = MAX(0, MIN(1,vol + delta));
    [AudioControl sharedInstanceOutput].volume = vol;
    [AudioControl sharedInstanceOutput].mute = (vol < VolumeAdjustIncrement*0.9);
    [BezelWindow showWithType:([AudioControl sharedInstanceOutput].mute ? kAudioOutputMute : kAudioOutputVolume) andValue:vol];
}

- (void)mute {
    
    BOOL mute = ![AudioControl sharedInstanceOutput].mute;
    [AudioControl sharedInstanceOutput].mute = mute;
    double vol = mute ? 0 : [AudioControl sharedInstanceOutput].volume;
    [BezelWindow showWithType:(mute ? kAudioOutputMute : kAudioOutputVolume) andValue:vol];

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
    triggered = NO;
    
    // special
    if (activeSegment == 2) {
        PostAuxKeyPress(NX_KEYTYPE_MUTE);
        return;
    }
    
    // set timer
    repeatTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (activeSegment == 0) {
            PostAuxKeyPress(NX_KEYTYPE_SOUND_DOWN);
            triggered = YES;
        } else if (activeSegment == 1) {
            PostAuxKeyPress(NX_KEYTYPE_SOUND_UP);
            triggered = YES;
        }
    }];
    [repeatTimer fire];
    
    // hide bezel window
    [BezelWindow hide];
}

- (void)shortPressChanged:(NSGestureRecognizer *)recognizer
{
}

- (void)shortPressEnded:(NSGestureRecognizer *)recognizer
{
    // key up
    if (activeSegment == 0) {
        if (triggered == NO) {
            PostAuxKeyPress(NX_KEYTYPE_SOUND_DOWN);
        }
    } else if (activeSegment == 1) {
        if (triggered == NO) {
            PostAuxKeyPress(NX_KEYTYPE_SOUND_UP);
        }
    }

    // done
    activeSegment = -1;
    [repeatTimer invalidate];

}

@end
