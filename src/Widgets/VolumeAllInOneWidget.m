/**
 * @file VolumeAllInOneWidget.m
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

#import "VolumeAllInOneWidget.h"
#import "ImageTitleView.h"
#import "AudioControl.h"
#import "BezelWindow.h"
#import "KeyEvent.h"

@interface VolumeAllInOneWidgetView : ImageTitleView
@end

@implementation VolumeAllInOneWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(WIDGET_STANDARD_WIDTH, NSViewNoIntrinsicMetric);
}
@end

@interface VolumeAllInOneWidget() {
    int lastSlidePosition;
    BOOL modified;
}
@end

@implementation VolumeAllInOneWidget

- (void)commonInit
{
    self.customizationLabel = @"Volume All-in-one";
    
    self.volumeOff = [NSImage imageNamed:@"AudioVolumeOff"];
    self.volumeLow = [NSImage imageNamed:@"AudioVolumeLow"];
    self.volumeMedium = [NSImage imageNamed:@"AudioVolumeMed"];
    self.volumeHigh = [NSImage imageNamed:@"AudioVolumeHigh"];
    self.volumeMute = [NSImage imageNamed:@"AudioVolumeMute"];

    ImageTitleView *view = [[[VolumeAllInOneWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 6.0;
    view.layer.backgroundColor = [[NSColor colorWithWhite:0.2109 alpha:1.0] CGColor];
    view.imageSize = NSMakeSize(36, 36);
    view.layoutOptions = ImageTitleViewLayoutOptionImage;
    
    NSPressGestureRecognizer *shortPress = [[[NSPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(shortPressAction:)] autorelease];
    shortPress.allowedTouchTypes = NSTouchTypeMaskDirect;
    shortPress.minimumPressDuration = 0;

    [view addGestureRecognizer:shortPress];
    
    self.view = view;
    
    [AudioControl sharedInstanceOutput];
    [self setVolumeImage];

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

- (void)audioControlNotification:(NSNotification *)notification
{
    [self setVolumeImage];
}

- (void)setVolumeImage
{
    ImageTitleView* imageTitleView = (ImageTitleView*) self.view;
    BOOL mute = [AudioControl sharedInstanceOutput].mute;
    if (mute) {
        [imageTitleView setImage:self.volumeMute];
    } else {
        double volume = [AudioControl sharedInstanceOutput].volume;
        if (volume < 0.25) {
            [imageTitleView setImage:self.volumeOff];
        } else if (volume < 0.5) {
            [imageTitleView setImage:self.volumeLow];
        } else if (volume < 0.75) {
            [imageTitleView setImage:self.volumeMedium];
        } else {
            [imageTitleView setImage:self.volumeHigh];
        }
    }
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
    lastSlidePosition = point.x;
    modified = NO;
    
    // hide bezel window
    [BezelWindow hide];
}

- (void)shortPressChanged:(NSGestureRecognizer *)recognizer
{
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
    if (positionDelta < 0) {
        PostAuxKeyPress(NX_KEYTYPE_SOUND_DOWN);
    } else if (positionDelta > 0) {
        PostAuxKeyPress(NX_KEYTYPE_SOUND_UP);
    }
    
    // update
    [self setVolumeImage];
}

- (void)shortPressEnded:(NSGestureRecognizer *)recognizer
{
    // key up
    if (modified == NO) {
        PostAuxKeyPress(NX_KEYTYPE_MUTE);
    }
}

@end
