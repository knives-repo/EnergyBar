//
//  NSRunningApplication+Utils.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/1/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "NSRunningApplication+Utils.h"

@implementation NSRunningApplication(Utils)

- (BOOL) isMicrosoftTeams {
    return [self.bundleIdentifier isEqualToString:@"com.microsoft.teams"];
}

@end
