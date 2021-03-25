//
//  dnd.m
//  EnergyBar
//
//  Created by Kevin Speranza on 24/03/2021.
//  Copyright © 2021 Kevin Speranza. All rights reserved.
//

#import "DndWidget.h"
#import "ImageTitleView.h"

@interface DndWidgetView : ImageTitleView
@end

@implementation DndWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(15, NSViewNoIntrinsicMetric);
}
@end

@implementation DndWidget
- (void)commonInit
{
    self.customizationLabel = @"DND Toggle";
    ImageTitleView *view = [[[DndWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 8.0;
    view.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    view.imageSize = NSMakeSize(15, 15);
    view.layoutOptions = ImageTitleViewLayoutOptionImage;
    
/*
    NSUserDefaults* defaults = [[NSUserDefaults alloc]initWithSuiteName:@"com.apple.notificationcenterui"];
    bool dnd = [defaults boolForKey:@"doNotDisturb"];
    
    if (dnd == 0)
    {
*/
        self.dndIcon = [NSImage imageNamed:@"dndIconWhite"];
/*
    }
    else
    {
        self.dndIcon = [NSImage imageNamed:@"dndIconPurple"];
    }
*/
    
    view.image = self.dndIcon;
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

- (void)longPressAction_:(NSGestureRecognizer *)recognizer
{
    if (NSGestureRecognizerStateBegan != recognizer.state)
        return;

    [self longPressAction:self];
    /*
    NSUserDefaults* defaults = [[NSUserDefaults alloc]initWithSuiteName:@"com.apple.notificationcenterui"];
    bool dnd = [defaults boolForKey:@"doNotDisturb"];
    [defaults synchronize];
    
    if (dnd == 0)
    {
        dnd = 1;
    }
    else
    {
        dnd = 0;
    }
     */
}

- (void)longPressAction:(id)sender
{
    NSString *source = @""
    "ignoring application responses\n"
       "tell application \"System Events\"\n"
            "key code {63, 111} using {control down}\n"
        "end tell\n"
    "end ignoring\n";

    NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:source] autorelease];
    NSDictionary *errorInfo = nil;
    [script executeAndReturnError:&errorInfo];
}
/*
- (void)viewWillAppear
{
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"SomeKey"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    // Testing...
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"test" forKey:@"SomeKey"];
    [defaults synchronize];
}

- (void)viewWillDisappear
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"SomeKey"];
}

- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context
{
    if([keyPath isEqual:@"SomeKey"])
    {
       NSLog(@"SomeKey change: %@", change);
    }
}
*/
@end
