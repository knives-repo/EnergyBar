//
//  NSRunningApplication+Utils.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/1/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "NSRunningApplication+Utils.h"

@implementation NSRunningApplication(Utils)

- (BOOL) isConferencingApp {
    return [self isMicrosoftTeams] || [self isWebexMeetings];
}

- (BOOL) isMicrosoftTeams {
    return [self.bundleIdentifier isEqualToString:@"com.microsoft.teams"];
}

- (BOOL) isWebexMeetings {
    return [self.bundleIdentifier isEqualToString:@"com.webex.meetingmanager"];
}

- (BOOL) isSpotify {
    return [self.bundleIdentifier isEqualToString:@"com.spotify.client"];
}

+ (BOOL) isMusicRunning {
    return [NSRunningApplication isApplicationRunning:@"com.apple.Music"];
}

+ (BOOL) isSpotifyRunning {
    return [NSRunningApplication isApplicationRunning:@"com.spotify.client"];
}

+ (BOOL) isApplicationRunning:(NSString*) bundleIdentifier {
    NSArray* runningApplications = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier];
    return (runningApplications != nil && runningApplications.count > 0);
}

@end
