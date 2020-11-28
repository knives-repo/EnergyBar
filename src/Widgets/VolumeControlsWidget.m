/**
 * @file VolumeControlsWidget.m
 *
 * @copyright 2020 Nicolas Bonamy
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import "VolumeControlsWidget.h"
#import "AudioControl.h"
#import "BezelWindow.h"
#import "KeyEvent.h"
#import "NSSegmentedControl+Utils.h"

#define VolumeAdjustIncrement					 (1.0/16.0)

@interface VolumeControlsWidget() {
    NSInteger activeSegment;
    NSTimer* scheduleTimer;
    NSTimer* repeatTimer;
    BOOL triggered;
}
@end

@implementation VolumeControlsWidget

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
    
    [control style];

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
    return [NSImage imageNamed:mute ? @"VolumeMuteOnAccent" : @"VolumeMuteOff"];
}

- (void)audioControlNotification:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view setImage:[self volumeMuteImage] forSegment:2];
    });
}

- (void)adjustVolumeBy:(double)delta {
    double vol = [AudioControl sharedInstanceOutput].volume;
    vol = MAX(0, MIN(1,vol + delta));
    [AudioControl sharedInstanceOutput].volume = vol;
    [AudioControl sharedInstanceOutput].mute = (vol < VolumeAdjustIncrement*0.9);
    [BezelWindow showLevelFor:([AudioControl sharedInstanceOutput].mute ? kAudioOutputMute : kAudioOutputVolume) withValue:vol];
}

- (void)mute {
    
    BOOL mute = ![AudioControl sharedInstanceOutput].mute;
    [AudioControl sharedInstanceOutput].mute = mute;
    double vol = mute ? 0 : [AudioControl sharedInstanceOutput].volume;
    [BezelWindow showLevelFor:(mute ? kAudioOutputMute : kAudioOutputVolume) withValue:vol];

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

    // hide bezel window
    [BezelWindow hide];

    // process now
    [self tick];

    // do this on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // set timer
        scheduleTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:NO block:^(NSTimer * _Nonnull timer) {
            scheduleTimer = nil;
            repeatTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
                triggered = YES;
                [self tick];
            }];
            [repeatTimer fire];
        }];
    
    });
    
}

- (void)shortPressChanged:(NSGestureRecognizer *)recognizer
{
}

- (void)shortPressEnded:(NSGestureRecognizer *)recognizer
{
    // disable timers now
    dispatch_async(dispatch_get_main_queue(), ^{
        [scheduleTimer invalidate];
        [repeatTimer invalidate];
        scheduleTimer = nil;
        repeatTimer = nil;
    });

    // done
    activeSegment = -1;

}

- (void)tick {
    PostAuxKeyPress(activeSegment == 0 ? NX_KEYTYPE_SOUND_DOWN : NX_KEYTYPE_SOUND_UP);
}

@end
