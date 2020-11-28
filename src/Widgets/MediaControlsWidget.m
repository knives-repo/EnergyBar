/**
 * @file MediaControlsWidget.m
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

#import "MediaControlsWidget.h"
#import "KeyEvent.h"
#import "NowPlaying.h"
#import "BezelWindow.h"
#import "NSImage+Utils.h"
#import "NSSegmentedControl+Utils.h"

@interface MediaControlsWidget()
@property (retain) NSImage* playImage;
@property (retain) NSImage* pauseImage;
@property (retain) NSImage* previousImage;
@property (retain) NSImage* nextImage;
@end

@implementation MediaControlsWidget

- (void)commonInit
{
    self.playImage = [[NSImage imageNamed:NSImageNameTouchBarPlayTemplate] tintedWithColor:[NSColor whiteColor]];
    self.pauseImage = [[NSImage imageNamed:NSImageNameTouchBarPauseTemplate] tintedWithColor:[NSColor whiteColor]];
    self.previousImage = [[NSImage imageNamed:NSImageNameTouchBarSkipBackTemplate] tintedWithColor:[NSColor whiteColor]];
    self.nextImage = [[NSImage imageNamed:NSImageNameTouchBarSkipAheadTemplate] tintedWithColor:[NSColor whiteColor]];

    NSSegmentedControl *control = [NSSegmentedControl
        segmentedControlWithImages:[NSArray arrayWithObjects:
            [self previousImage],
            [self playPauseImage],
            [self nextImage],
            nil]
        trackingMode:NSSegmentSwitchTrackingMomentary
        target:self
        action:@selector(click:)];
    control.translatesAutoresizingMaskIntoConstraints = NO;
    control.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    control.tag = 'ctrl';
    
    [control style];

    self.customizationLabel = @"Media";
    self.view = control;
    
    [NowPlaying sharedInstance];

}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];

    [super dealloc];
}

- (NSImage *)playPauseImage
{
    BOOL playing = [NowPlaying sharedInstance].playing;
    return playing ? [self pauseImage] : [self playImage];
}

- (void)nowPlayingNotification:(NSNotification *)notification
{
    // first update icon
    NSSegmentedControl *control = [self.view viewWithTag:'ctrl'];
    [control setImage:[self playPauseImage] forSegment:1];
    
    // parent
    [super nowPlayingNotification:notification];

}

- (void)click:(id)sender
{
    NSSegmentedControl *control = sender;
    switch (control.selectedSegment)
    {
        case 0:
            // previous
            PostAuxKeyPress(NX_KEYTYPE_PREVIOUS);
            break;
        case 1:
            // play
            [self playPause];
            //PostAuxKeyPress(NX_KEYTYPE_PLAY);
            break;
        case 2:
            // next
            PostAuxKeyPress(NX_KEYTYPE_NEXT);
            break;
    }
}

@end
