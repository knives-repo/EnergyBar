//
//  MediaWidgetBase.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/2/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import "MediaWidgetBase.h"
#import "KeyEvent.h"
#import "NowPlaying.h"
#import "BezelWindow.h"
#import "NSRunningApplication+Utils.h"

@implementation MediaNotificationController

- (id) init
{
    self = [super initWithNibName:@"MediaNotification" bundle:nil];
    [NowPlaying sharedInstance];
    return self;
}

- (void) viewDidLoad {
    
    // fill data
    NowPlaying* instance = [NowPlaying sharedInstance];
    [self.iconView setImage:instance.appIcon];
    [self.titleView setStringValue:SafeStringValue(instance.title)];
    [self.artistView setStringValue:SafeStringValue(instance.artist)];
}

@end

@interface MediaWidgetBase()
@property (assign) BOOL autoPlay;
@property (assign) BOOL playSpotify;
@end

@implementation MediaWidgetBase

- (void)viewWillAppear
{
    // init
    self.autoPlay = NO;
    
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
        
        // if different than previous
        if (self.currentTitle == nil || [self.currentTitle isEqualToString:[NowPlaying sharedInstance].title] == NO) {
            
            // save
            self.currentTitle = [NowPlaying sharedInstance].title;
            
            // song title
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"mediaShowSongTitle"] == YES) {
                
                // need to have a proper title
                if ([NowPlaying sharedInstance].title != nil) {
                    
                    // not if app is frontmost
                    NSRunningApplication* frontMostApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
                    if ([frontMostApp.bundleIdentifier isEqualToString:[NowPlaying sharedInstance].appBundleIdentifier] == NO) {
                        MediaNotificationController* controller = [[[MediaNotificationController alloc] init] autorelease];
                        [BezelWindow showWithView:controller.view inDarkMode:YES];
                    }
                
                }
            }
            
        }
    
    } else {
        self.currentTitle = nil;
    }

}

- (void) playPause
{
    // collect some info
    NSURL* spotifyURL = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:[NSURL URLWithString:@"spotify://"]];
    //BOOL spotifyPlaying = [[NowPlaying sharedInstance].appBundleIdentifier isEqualToString:@"com.spotify.client"];
    BOOL spotifyFrontMost = [[[NSWorkspace sharedWorkspace] frontmostApplication] isSpotify];
    BOOL someonePlaying = [NowPlaying sharedInstance].appBundleIdentifier != nil;
    BOOL spotifyRunning = [NSRunningApplication isSpotifyRunning];
    BOOL musicRunning = [NSRunningApplication isMusicRunning];
    
    // if really no one else if playing
    if (musicRunning == NO && someonePlaying == NO) {

        // spotify
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"mediaFavorSpotify"] && spotifyURL != nil) {
            
            // if not running, will have to play when finished launching
            self.playSpotify = (self.autoPlay && spotifyRunning == NO);
            
            // launch or bring foremost
            [[NSWorkspace sharedWorkspace] openURL:spotifyURL];
            
            // if already running, app switch will not happen
            // so we can directly tell spotify to play
            if (spotifyFrontMost == YES || (self.autoPlay && spotifyRunning)) {
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

- (void) tellSpotifyToPlay:(BOOL) waitLonger
{
    // space
    [NSTimer scheduledTimerWithTimeInterval:(waitLonger ? 3 : 0.25) repeats:NO block:^(NSTimer * _Nonnull timer) {
        PostKeyPress(49, 0);
    }];
}

- (void) showLyrics
{
    NSString* q = [NSString stringWithFormat:@"%@ %@ lyrics", [NowPlaying sharedInstance].title, [NowPlaying sharedInstance].artist];
    q = [q stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    q = [q stringByReplacingOccurrencesOfString:@"?" withString:@"%3F"];
    q = [q stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
    q = [q stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    q = [q stringByReplacingOccurrencesOfString:@"#" withString:@"%23"];
    NSString* url = [NSString stringWithFormat:@"https://www.google.com/search?q=%@", q];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

@end
