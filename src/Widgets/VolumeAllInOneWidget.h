/**
 * @file VolumeAllInOneWidget.h
 *
 * @copyright 2020 Nicolas Bonamy
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import <Cocoa/Cocoa.h>
#import "CustomWidget.h"

@interface VolumeAllInOneWidget : CustomWidget
@property (retain) NSImage *volumeOff;
@property (retain) NSImage *volumeLow;
@property (retain) NSImage *volumeMedium;
@property (retain) NSImage *volumeHigh;
@property (retain) NSImage *volumeMute;
@end
