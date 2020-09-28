/**
 * @file VolumeControlWidget.m
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

#define VolumeAdjustIncrement					 (1.0/16.0)

@implementation VolumeWidget

- (void)commonInit
{
    NSSegmentedControl *control = [NSSegmentedControl
        segmentedControlWithImages:[NSArray arrayWithObjects:
            [NSImage imageNamed:NSImageNameTouchBarAudioOutputVolumeLowTemplate],
            [NSImage imageNamed:NSImageNameTouchBarAudioOutputVolumeHighTemplate],
            [self volumeMuteImage],
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

- (void)click:(id)sender
{
    NSSegmentedControl *control = sender;
    switch (control.selectedSegment)
    {
        case 0:
            // volume down
            PostAuxKeyPress(NX_KEYTYPE_SOUND_DOWN);
            //[self adjustVolumeBy:-VolumeAdjustIncrement];
            break;
        case 1:
            // volume up
            PostAuxKeyPress(NX_KEYTYPE_SOUND_UP);
            //[self adjustVolumeBy:+VolumeAdjustIncrement];
            break;
        case 2:
            PostAuxKeyPress(NX_KEYTYPE_MUTE);
            //[self mute];
            break;
    }
}

@end
