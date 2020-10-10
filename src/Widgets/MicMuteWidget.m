/**
 * @file MicMuteWidget.m
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

#import "MicMuteWidget.h"
#import "AudioControl.h"
#import "BezelWindow.h"
#import "NSColor+Hex.h"
#import "KeyEvent.h"
#import "NSRunningApplication+Utils.h"

@interface MicMuteWidget()
@property (retain) NSRunningApplication* runningApplication;
@property (retain) NSTimer* refreshTimer;
@property (retain) NSImage *micOnImage;
@property (retain) NSImage *micOffImage;
@property (assign) BOOL muteToRestore;
@property (assign) BOOL restoreMute;
@end

@implementation MicMuteWidget

- (void)commonInit
{
    // super
    [super commonInit];
    
    // experimental
    self.applicationMute = [[NSUserDefaults standardUserDefaults] boolForKey:@"micmuteApplicationMute"];

    // customization
    self.customizationLabel = @"Mic Mute";
    self.micOnImage = [NSImage imageNamed:@"MicOn"];
    self.micOffImage = [NSImage imageNamed:@"MicOff"];
    
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

    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(didActivateApplication:)
        name:NSWorkspaceDidActivateApplicationNotification
        object:nil];
    
    [self checkRunningApplication];

}

- (void)viewDidDisappear
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self];
}

- (void)setApplicationMute:(BOOL)value
{
    self->_applicationMute = value;
    [self checkRunningApplication];
}

- (void)audioControlNotification:(NSNotification *)notification
{
    [self setMicMuteImage];
}

- (void)setMicMuteImage
{
    // when application mute we do not know the status
    if (self.applicationMute && [self isMutableAppRunning]) {
        [self updateWithImage:self.micOnImage andBackgroundColor:[NSColor colorFromHex:0x0078d4]];
        return;
    }
    
    // default
    BOOL mute = [AudioControl sharedInstanceInput].mute;
    NSImage* image = mute ? _micOffImage : _micOnImage;
    NSColor* bgColor = mute ? [NSColor redColor] : [NSColor colorFromHex:0x008000];
    [self updateWithImage:image andBackgroundColor:bgColor];
}

- (void)updateWithImage:(NSImage*) image andBackgroundColor:(NSColor*) bgColor {

    // we will run this twice
    dispatch_block_t update = ^{
        [self setImage:image];
        [self setBackgroundColor:bgColor];
    };
    
    // run this on main thread
    dispatch_async(dispatch_get_main_queue(), update);
    //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), update);
    //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), update);
}

- (void)tapAction:(id)sender
{
    if (self.applicationMute && [self isMutableAppRunning]) {

        if ([self.runningApplication isMicrosoftTeams] || [self.runningApplication isWebexMeetings]) {

            // Cmd + Shift + M toggle mute
            PostKeyPress(46, kCGEventFlagMaskShift | kCGEventFlagMaskCommand);
            
            // done
            return;
            
        }
        
    }
        
    // modify
    BOOL mute = [AudioControl sharedInstanceInput].mute;
    [AudioControl sharedInstanceInput].mute = !mute;
    
    // reload to make sure something happened
    mute = [AudioControl sharedInstanceInput].mute;
    [BezelWindow showLevelFor:(mute ? kAudioInputMute : kAudioInputOn) withValue:-1];
    [self setMicMuteImage];

}

- (void)didActivateApplication:(NSNotification *)notification
{
    [self checkRunningApplication];
}

- (void)checkRunningApplication
{
    // restore
    if (self.restoreMute) {
        [AudioControl sharedInstanceInput].mute = self.muteToRestore;
        self.restoreMute = NO;
    }
    
    // update
    self.runningApplication = [[NSWorkspace sharedWorkspace] menuBarOwningApplication];
    //LOG("[MICMUTE] App Bundle = %@", self.runningApplication.bundleIdentifier);
    
    // check if we use application mute
    if (self.applicationMute && [self isMutableAppRunning]) {
        
        // save
        self.muteToRestore = [AudioControl sharedInstanceInput].mute;
        self.restoreMute = YES;
        
        // now unmute
        [AudioControl sharedInstanceInput].mute = FALSE;

    }
    
    // update
    [self setMicMuteImage];

}

- (BOOL) isMutableAppRunning {
    return ([self.runningApplication isMicrosoftTeams] || [self.runningApplication isWebexMeetings]);
}

@end
