/**
 * @file MediaWidget.m
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

#import "MediaWidget.h"
#import "KeyEvent.h"
#import "NowPlaying.h"
#import "BezelWindow.h"
#import "NSSegmentedControl+Utils.h"

@interface MediaWidget()
@property (retain) NSString* currentTitle;
@end

@implementation MediaWidget

- (void)commonInit
{
    NSSegmentedControl *control = [NSSegmentedControl
        segmentedControlWithImages:[NSArray arrayWithObjects:
            [NSImage imageNamed:NSImageNameTouchBarSkipBackTemplate],
            [self playPauseImage],
            [NSImage imageNamed:NSImageNameTouchBarSkipAheadTemplate],
            nil]
        trackingMode:NSSegmentSwitchTrackingMomentary
        target:self
        action:@selector(click:)];
    control.translatesAutoresizingMaskIntoConstraints = NO;
    control.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    control.tag = 'ctrl';
    
    [control setSegmentsWidth:WIDGET_STANDARD_WIDTH];

    self.customizationLabel = @"Media";
    self.view = control;
    
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
        selector:@selector(nowPlayingNotification:)
        name:NowPlayingStateNotification
        object:nil];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(nowPlayingNotification:)
        name:NowPlayingInfoNotification
        object:nil];
}

- (void)viewDidDisappear
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];
}
- (NSImage *)playPauseImage
{
    BOOL playing = [NowPlaying sharedInstance].playing;
    return [NSImage imageNamed:playing ?
        NSImageNameTouchBarPauseTemplate : NSImageNameTouchBarPlayTemplate];
}

- (void)nowPlayingNotification:(NSNotification *)notification
{
    // first update icon
    NSSegmentedControl *control = [self.view viewWithTag:'ctrl'];
    [control setImage:[self playPauseImage] forSegment:1];
    
    // notify track change
    if ([NowPlaying sharedInstance].playing) {
        if (self.currentTitle == nil || [self.currentTitle isEqualToString:[NowPlaying sharedInstance].title] == NO) {
            self.currentTitle = [NowPlaying sharedInstance].title;
            [BezelWindow showWithMessage:self.currentTitle];
        }
    }

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
            PostAuxKeyPress(NX_KEYTYPE_PLAY);
            break;
        case 2:
            // next
            PostAuxKeyPress(NX_KEYTYPE_NEXT);
            break;
    }
}

@end
