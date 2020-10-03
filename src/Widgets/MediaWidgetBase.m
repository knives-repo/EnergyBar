//
//  MediaWidgetBase.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/2/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "MediaWidgetBase.h"
#import "KeyEvent.h"
#import "NowPlaying.h"
#import "BezelWindow.h"
#import "NSRunningApplication+Utils.h"

@interface MediaWidgetBase()
@property (assign) BOOL playSpotify;
@end

@implementation MediaWidgetBase

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

    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(didActivateApplication:)
        name:NSWorkspaceDidActivateApplicationNotification
        object:nil];

}

- (void)viewDidDisappear
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];
}

- (void)nowPlayingNotification:(NSNotification *)notification
{
    // last app
    //NSLog(@"%@", [NowPlaying sharedInstance].appBundleIdentifier);
    
    // notify track change
    if ([NowPlaying sharedInstance].playing) {
        if (self.currentTitle == nil || [self.currentTitle isEqualToString:[NowPlaying sharedInstance].title] == NO) {
            self.currentTitle = [NowPlaying sharedInstance].title;
            [BezelWindow showWithMessage:self.currentTitle];
        }
    } else {
        self.currentTitle = nil;
    }

}

- (void) playPause {

    // collect some info
    NSURL* spotifyURL = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:[NSURL URLWithString:@"spotify://"]];
    //BOOL spotifyPlaying = [[NowPlaying sharedInstance].appBundleIdentifier isEqualToString:@"com.spotify.client"];
    //BOOL spotifyFrontMost = [[[NSWorkspace sharedWorkspace] frontmostApplication] isSpotify];
    BOOL someonePlaying = [NowPlaying sharedInstance].appBundleIdentifier != nil;
    BOOL spotifyRunning = [NSRunningApplication isSpotifyRunning];
    BOOL musicRunning = [NSRunningApplication isMusicRunning];
    
    // if really no one else if playing
    if (musicRunning == NO && someonePlaying == NO) {

        // spotify
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"mediaFavorSpotify"] && spotifyURL != nil) {
            
            // if not running, will have to play when finished launching
            self.playSpotify = (spotifyRunning == NO);
            
            // launch or bring foremost
            [[NSWorkspace sharedWorkspace] openURL:spotifyURL];
            
            // if already running, app switch will not happen
            // so we can directly tell spotify to play
            if (spotifyRunning == YES) {
                [self tellSpotifyToPlay:NO];
            }
            
            // done
            return;

        }
        
    }
    
    // default
    PostAuxKeyPress(NX_KEYTYPE_PLAY);

}

- (void)didActivateApplication:(id) sender
{
    // check running app
    NSRunningApplication* runningApplication = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if ([runningApplication isSpotify] && self.playSpotify) {
        
        // this is launching so wait a bit more
        [self tellSpotifyToPlay:YES];
        self.playSpotify = NO;

    }

}

- (void) tellSpotifyToPlay:(BOOL) waitLonger {
    
    // space
    [NSTimer scheduledTimerWithTimeInterval:(waitLonger ? 3 : 0.5) repeats:NO block:^(NSTimer * _Nonnull timer) {
        PostKeyPress(49, 0);
    }];

}

@end
