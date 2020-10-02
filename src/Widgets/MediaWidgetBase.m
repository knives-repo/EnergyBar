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

@implementation MediaWidgetBase

- (void)nowPlayingNotification:(NSNotification *)notification
{
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
    BOOL spotifyPlaying = [[NowPlaying sharedInstance].appBundleIdentifier isEqualToString:@"com.spotify.client"];
    BOOL spotifyFrontMost = [[[NSWorkspace sharedWorkspace] frontmostApplication] isSpotify];
    BOOL spotifyRunning = [NSRunningApplication isSpotifyRunning];
    BOOL musicRunning = [NSRunningApplication isMusicRunning];
    
    // this may require special stuff
    if (musicRunning == NO) {

        // spotify
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"mediaFavorSpotify"]) {
            
            // if not already playing
            if (spotifyPlaying == NO) {
                
                if (spotifyRunning == NO || spotifyFrontMost == NO) {

                    // open it
                    NSURL* spotifyURL = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:[NSURL URLWithString:@"spotify://"]];
                    if (spotifyURL != nil) {
                        [[NSWorkspace sharedWorkspace] openURL:spotifyURL];
                        return;
                    }

                } else {
                    
                    // start playing
                    PostKeyPress(49, 0);
                    return;

                }
                
            }
        
        }
        
    }
    
    // default
    PostAuxKeyPress(NX_KEYTYPE_PLAY);

}

@end
