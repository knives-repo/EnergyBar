//
//  NSSegmentedControl+Utils.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/28/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSSegmentedControl(Utils)

- (void)setSegmentsWidth:(int)w;
- (NSInteger)segmentForX:(CGFloat)x;

@end

NS_ASSUME_NONNULL_END
