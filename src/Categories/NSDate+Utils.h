//
//  NSDate+Utils.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/29/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate(Utils)

+ (NSDate*) dateFromComponents:(NSDateComponents*) components;
+ (NSDate*) nextTickForEverySeconds:(int) frequency withDelta:(int) delta;

- (NSTimeInterval) timeIntervalSinceMinuteStart;

- (BOOL) isInPast;
- (BOOL) isInFuture;

- (BOOL) isNowWithinMinutes:(NSUInteger) minutes;

- (NSDateComponents*) components;

- (NSDate*) dateBySettingSeconds:(NSUInteger) seconds;

@end

NS_ASSUME_NONNULL_END
