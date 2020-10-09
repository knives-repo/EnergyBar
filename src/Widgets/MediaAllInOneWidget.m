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

#define ACTIVATION_DELTA 32
#define LYRICS_TIME 1

typedef enum {
    ActionPlayPause,
    ActionNext,
    ActionPrev,
    //ActionLyrics,
    ActionCancelled
} Action;

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
    Action action;
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

-(void)setPressActionIcon {
    
    BOOL playing = [NowPlaying sharedInstance].playing;
    switch (action) {
        case ActionNext:
            [self.imageTitleView setImage:self.nextImage];
            break;
        case ActionPrev:
            [self.imageTitleView setImage:self.previousImage];
            break;
        case ActionPlayPause:
            playing = !playing;
        default:
            [self.imageTitleView setImage:playing ? self.pauseImage : self.playImage];
            break;
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
    action = ActionPlayPause;
    
    // hide bezel window
    [BezelWindow hide];
    
    // timer for lyrics
    [NSTimer scheduledTimerWithTimeInterval:LYRICS_TIME repeats:NO block:^(NSTimer * _Nonnull timer) {
        if (action == ActionPlayPause) {
            [self showLyrics];
            action = ActionCancelled;
            [self setPressActionIcon];
        }
    }];
    
    // update icon now
    [self setPressActionIcon];

}

- (void)shortPressChanged:(NSGestureRecognizer *)recognizer
{
    // calc delta
    NSPoint point = [recognizer locationInView:self.view];
    int positionDelta = point.x - initialSlidePosition;
    
    // cancelled
    if (action != ActionCancelled) {

        // set image
        if (positionDelta < -ACTIVATION_DELTA) {
            action = ActionPrev;
        } else if (positionDelta > ACTIVATION_DELTA) {
            action = ActionNext;
        } else if (action == ActionPrev || action == ActionNext) {
            action = ActionCancelled;
        }
        
    }
    
    // update icon now
    [self setPressActionIcon];

}

- (void)shortPressEnded:(NSGestureRecognizer *)recognizer
{
    // save and reset
    Action actionToPerform = action;
    action = ActionCancelled;
    
    // key up
    switch (actionToPerform) {
        case ActionNext:
            PostAuxKeyPress(NX_KEYTYPE_NEXT);
            break;
        case ActionPrev:
            PostAuxKeyPress(NX_KEYTYPE_PREVIOUS);
            break;
        case ActionPlayPause:
            [self playPause];
            break;
        default:
            break;
    };

    // update icon now
    //[self setPressActionIcon];

}

@end
