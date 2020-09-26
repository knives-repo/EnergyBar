//
//  ControlWidgetLevelView.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/25/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ControlWidgetLevelView : NSView
@property (getter=value, setter=setValue:) double value;
@property (getter=indicatorWidth, setter=setIndicatorWidth:) CGFloat indicatorWidth;
@property (assign) CGFloat inset;
@property (assign) NSInteger tag;
@property (retain) NSColor *backgroundColor;
@property (retain) NSColor *foregroundColor;
@end

NS_ASSUME_NONNULL_END
