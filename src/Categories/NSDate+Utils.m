//
//  NSDate+Utils.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/29/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import "NSDate+Utils.h"

@implementation NSDate(Utils)

- (BOOL) isYesterday {
    return [[NSCalendar currentCalendar] isDateInYesterday:self];
}

- (BOOL) isToday {
    return [[NSCalendar currentCalendar] isDateInToday:self];
}

- (BOOL) isTomorrow {
    return [[NSCalendar currentCalendar] isDateInTomorrow:self];
}

- (BOOL) isInPast {
    return [self timeIntervalSinceNow] < 0;
}

- (BOOL) isInFuture {
    return [self timeIntervalSinceNow] > 0;
}

- (BOOL) isNowWithinMinutes:(NSUInteger) minutes {
    return fabs([self timeIntervalSinceNow]) <= minutes * 60;
}

- (NSTimeInterval) timeIntervalSinceMinuteStart {
    NSDate* now = [[NSDate date] dateBySettingSeconds:0];
    return [self timeIntervalSinceDate:now];
}

- (NSDateComponents*) components {
    int units = NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay;
    units = units | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    return [[NSCalendar currentCalendar] components:units fromDate:self];
}

+ (NSDate*) dateFromComponents:(NSDateComponents*) components {
    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

- (NSDate*) dateBySettingSeconds:(NSUInteger) seconds {
    NSDateComponents* components = [self components];
    return [self dateByAddingTimeInterval:-components.second];
}

+ (NSDate*) nextTickForEverySeconds:(int) frequency withDelta:(int) delta {

    // get current
    NSDate* tick = [NSDate date];
    NSDateComponents* components = [tick components];
    
    // calc next second
    NSInteger seconds = components.second;
    int next = (round((double)(seconds) / (double)(frequency)) + 1) * frequency;
    if (next == 0) {
        next = frequency;
    }
    
    // add and done
    return [tick dateByAddingTimeInterval:next - seconds + delta];
}

@end
