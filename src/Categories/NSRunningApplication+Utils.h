//
//  NSRunningApplication+Utils.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/1/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSRunningApplication(Utils)

- (BOOL) isConferencingApp;

- (BOOL) isMicrosoftTeams;
- (BOOL) isWebexMeetings;

- (BOOL) isSpotify;

+ (BOOL) isMusicRunning;
+ (BOOL) isSpotifyRunning;

@end

NS_ASSUME_NONNULL_END
