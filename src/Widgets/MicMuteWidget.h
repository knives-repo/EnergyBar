/**
 * @file LockWidget.h
 *
 * @copyright 2018 Brian Hartvigsen
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

@interface MicMuteWidget : CustomWidget
@property (retain) NSImage *micOnImage;
@property (retain) NSImage *micOffImage;
@end
