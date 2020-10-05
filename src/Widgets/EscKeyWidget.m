/**
 * @file EscKeyWidget.m
 *
 * @copyright 2018-2019 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import "EscKeyWidget.h"
#import "KeyEvent.h"

@interface EscKeyWidgetButton : NSButton
@end

@implementation EscKeyWidgetButton
- (NSSize)intrinsicContentSize
{
    NSSize size = [super intrinsicContentSize];
    size.width = MIN(size.width, 64);
    return size;
}

- (BOOL)isHitTestAlwaysEnabled_
{
    return YES;
}
@end

@implementation EscKeyWidget
- (void)commonInit
{
    self.customizationLabel = @"Esc Key";
    self.view = [EscKeyWidgetButton buttonWithTitle:@"esc" target:self action:@selector(click:)];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)click:(id)sender
{
    PostKeyPress(0x35/*kVK_Escape*/, (uint32_t) [NSEvent modifierFlags]);
}
@end
