/**
 * @file MediaAllInOneWidget.m
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

#import "MediaAllInOneWidget.h"
#import "ImageTitleView.h"
#import "NowPlaying.h"
#import "BezelWindow.h"
#import "KeyEvent.h"
#import "NSImage+Utils.h"
#import "NSRunningApplication+Utils.h"

#define ACTIVATION_DELTA 32

@interface MediaAllInOneWidgetView : ImageTitleView
@end

@implementation MediaAllInOneWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(WIDGET_STANDARD_WIDTH, NSViewNoIntrinsicMetric);
}
@end

@interface MediaAllInOneWidget() {
    int initialSlidePosition;
    BOOL activated;
}
@property (retain) ImageTitleView* imageTitleView;
@property (retain) NSImage* playImage;
@property (retain) NSImage* pauseImage;
@property (retain) NSImage* previousImage;
@property (retain) NSImage* nextImage;
@end

@implementation MediaAllInOneWidget

- (void)commonInit
{
    self.customizationLabel = @"Media All-in-one";
    
    self.playImage = [[NSImage imageNamed:NSImageNameTouchBarPlayTemplate] tintedWithColor:[NSColor whiteColor]];
    self.pauseImage = [[NSImage imageNamed:NSImageNameTouchBarPauseTemplate] tintedWithColor:[NSColor whiteColor]];
    self.previousImage = [[NSImage imageNamed:NSImageNameTouchBarSkipBackTemplate] tintedWithColor:[NSColor whiteColor]];
    self.nextImage = [[NSImage imageNamed:NSImageNameTouchBarSkipAheadTemplate] tintedWithColor:[NSColor whiteColor]];

    self.imageTitleView = [[[MediaAllInOneWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    self.imageTitleView.wantsLayer = YES;
    self.imageTitleView.layer.cornerRadius = 6.0;
    self.imageTitleView.layer.backgroundColor = [[NSColor colorWithWhite:0.2109 alpha:1.0] CGColor];
    self.imageTitleView.imageSize = NSMakeSize(36, 36);
    self.imageTitleView.layoutOptions = ImageTitleViewLayoutOptionImage;
    
    NSPressGestureRecognizer *shortPress = [[[NSPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(shortPressAction:)] autorelease];
    shortPress.allowedTouchTypes = NSTouchTypeMaskDirect;
    shortPress.minimumPressDuration = 0;

    [self.imageTitleView addGestureRecognizer:shortPress];
    
    self.view = self.imageTitleView;
        
    [NowPlaying sharedInstance];
    
    [self nowPlayingNotification:nil];

}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];

    self.playImage = nil;
    self.pauseImage = nil;
    self.previousImage = nil;
    self.nextImage = nil;
    
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
    return playing ? self.pauseImage : self.playImage;
}

- (void)nowPlayingNotification:(NSNotification *)notification
{
    // first update icon
    [self.imageTitleView setImage:[self playPauseImage]];

    // parent
    [super nowPlayingNotification:notification];

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
    initialSlidePosition = point.x;
    activated = NO;
    
    // hide bezel window
    [BezelWindow hide];
}

- (void)shortPressChanged:(NSGestureRecognizer *)recognizer
{
    // calc delta
    NSPoint point = [recognizer locationInView:self.view];
    int positionDelta = point.x - initialSlidePosition;
    
    // set image
    if (positionDelta < -ACTIVATION_DELTA) {
        [self.imageTitleView setImage:self.previousImage];
        activated = YES;
    } else if (positionDelta > ACTIVATION_DELTA) {
        [self.imageTitleView setImage:self.nextImage];
        activated = YES;
    } else {
        if (activated == YES) {
            [self.imageTitleView setImage:[self playPauseImage]];
        } else {
            BOOL playing = [NowPlaying sharedInstance].playing;
            [self.imageTitleView setImage:playing ? self.playImage : self.pauseImage];
        }
    }

}

- (void)shortPressEnded:(NSGestureRecognizer *)recognizer
{
    // key up
    NSPoint point = [recognizer locationInView:self.view];
    int positionDelta = point.x - initialSlidePosition;
    if (positionDelta < -ACTIVATION_DELTA) {
        PostAuxKeyPress(NX_KEYTYPE_PREVIOUS);
    } else if (positionDelta > ACTIVATION_DELTA) {
        PostAuxKeyPress(NX_KEYTYPE_NEXT);
    } else if (activated == NO) {
        [self playPause];
    }
}

@end
