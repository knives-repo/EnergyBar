//
//  dnd.m
//  EnergyBar
//
//  Created by Kevin Speranza on 24/03/2021.
//  Copyright © 2021 Kevin Speranza. All rights reserved.
//

#import "NumiWidget.h"
#import "ImageTitleView.h"

@interface NumiWidgetView : ImageTitleView
@end

@implementation NumiWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(40, NSViewNoIntrinsicMetric);
}
@end

@implementation NumiWidget
- (void)commonInit
{
    self.customizationLabel = @"Numi Toggle";
    ImageTitleView *view = [[[NumiWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 4.0;
    view.layer.backgroundColor = [[NSColor colorWithWhite:0.5 alpha:0.5] CGColor];
    view.imageSize = NSMakeSize(20, 20);
    view.layoutOptions = ImageTitleViewLayoutOptionImage;
    self.numiIcon = [NSImage imageNamed:@"Calculator"];
    view.image = self.numiIcon;
    self.view = view;
    
    NSPressGestureRecognizer *longPressRecognizer = [[[NSPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(longPressAction_:)] autorelease];
    longPressRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    longPressRecognizer.minimumPressDuration = ShortPressDuration;
    [self.view addGestureRecognizer:longPressRecognizer];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)longPressAction_:(NSGestureRecognizer *)recognizer
{
    if (NSGestureRecognizerStateBegan != recognizer.state)
        return;

    [self longPressAction:self];
}

- (void)longPressAction:(id)sender
{
    NSString *source = @""
    "ignoring application responses\n"
       "tell application \"System Events\"\n"
            "key code {63, 103} using {control down}\n"
        "end tell\n"
    "end ignoring\n";

    NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:source] autorelease];
    NSDictionary *errorInfo = nil;
    [script executeAndReturnError:&errorInfo];
}

@end
