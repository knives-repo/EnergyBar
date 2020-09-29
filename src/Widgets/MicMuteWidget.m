/**
 * @file MicMuteWidget.m
 *
 * @copyright 2018 Brian Hartvigsen
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import "MicMuteWidget.h"
#import "ImageTitleView.h"
#import "AudioControl.h"
#import "BezelWindow.h"
#import "NSColor+Hex.h"

@interface MicMuteWidgetView : ImageTitleView
@end

@implementation MicMuteWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(WIDGET_STANDARD_WIDTH, NSViewNoIntrinsicMetric);
}
@end

@implementation MicMuteWidget

- (void)commonInit
{
    self.customizationLabel = @"Mic Mute";
    self.micOnImage = [NSImage imageNamed:@"MicOn"];
    self.micOffImage = [NSImage imageNamed:@"MicOff"];
    
    ImageTitleView *view = [[[MicMuteWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 6.0;
    view.imageSize = NSMakeSize(36, 36);
    view.layoutOptions = ImageTitleViewLayoutOptionImage;
    
    NSClickGestureRecognizer *tapRecognizer = [[[NSClickGestureRecognizer alloc]
                                                initWithTarget:self action:@selector(tapAction:)] autorelease];
    tapRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    [view addGestureRecognizer:tapRecognizer];
    
    self.view = view;
    
    [AudioControl sharedInstanceInput];
    [self setMicMuteImage];

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
    [self setMicMuteImage];
}

- (void)setMicMuteImage
{
    BOOL mute = [AudioControl sharedInstanceInput].mute;
    NSImage* image = mute ? _micOffImage : _micOnImage;
    NSColor* bgColor = mute ? [NSColor redColor] : [NSColor colorFromHex:0x008000];
    [((ImageTitleView*) self.view) setImage:image];
    self.view.layer.backgroundColor = [bgColor CGColor];
}

- (void)tapAction:(id)sender
{
    // modify
    BOOL mute = [AudioControl sharedInstanceInput].mute;
    [AudioControl sharedInstanceInput].mute = !mute;
    
    // reload to make sure something happened
    mute = [AudioControl sharedInstanceInput].mute;
    [BezelWindow showWithType:(mute ? kAudioInputMute : kAudioInputOn) andValue:-1];

}

@end
