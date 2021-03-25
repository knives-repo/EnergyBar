/**
 * @file LockWidget.m
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

#import "LockWidget.h"
#import "ImageTitleView.h"

void SACLockScreenImmediate(void);

@interface LockWidgetView : ImageTitleView
@end

@implementation LockWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(15, NSViewNoIntrinsicMetric);
}
@end

@implementation LockWidget
- (void)commonInit
{
    self.customizationLabel = @"Lock Screen";
    self.lockImage = [NSImage imageNamed:@"coffeeIcon"];
    ImageTitleView *view = [[[LockWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 8.0;
    view.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:1.0] CGColor];
    view.imageSize = NSMakeSize(18, 18);
    view.layoutOptions = ImageTitleViewLayoutOptionImage;
    view.image = self.lockImage;
    
    /* TAP FOR LOCK
    NSClickGestureRecognizer *tapRecognizer = [[[NSClickGestureRecognizer alloc]
                                                initWithTarget:self action:@selector(tapAction:)] autorelease];
    tapRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    [view addGestureRecognizer:tapRecognizer];
    */
    
    self.view = view;
    
    NSPressGestureRecognizer *longPressRecognizer = [[[NSPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(longPressAction_:)] autorelease];
    longPressRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    longPressRecognizer.minimumPressDuration = SuperLongPressDuration;
    [self.view addGestureRecognizer:longPressRecognizer];
}

- (void)dealloc
{
    [super dealloc];
}

/* TAP ACTION
- (void)tapAction:(id)sender
{
    SACLockScreenImmediate();
}
 */

- (void)longPressAction_:(NSGestureRecognizer *)recognizer
{
    if (NSGestureRecognizerStateBegan != recognizer.state)
        return;

    [self longPressAction:self];
}

- (void)longPressAction:(id)sender
{
    SACLockScreenImmediate();
}
@end
