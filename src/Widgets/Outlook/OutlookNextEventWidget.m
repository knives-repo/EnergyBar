//
//  OutlookNextEventWidget.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/28/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "OutlookNextEventWidget.h"
#import "NSColor+Hex.h"

#define SafeStringValue(x) (x == nil ? @"" : x)

#define RESET_AFTER_USER_NEXT 10

@interface NextEventsWidgetView : NSView

@property (assign) IBOutlet NSView *contentView;
@property (assign) IBOutlet NSView *busyWellView;
@property (assign) IBOutlet NSView *linkWellView;
@property (assign) IBOutlet NSView *showAsView;
@property (assign) IBOutlet NSTextField *timeView;
@property (assign) IBOutlet NSTextField *titleView;
@property (assign) IBOutlet NSButton *joinButton;
@property (assign) IBOutlet NSButton *nextButton;
@property (assign) IBOutlet NSLayoutConstraint *joinButtonWidthConstraint;

@end

@implementation NextEventsWidgetView

@synthesize contentView;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    [self setup];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    [self setup];
    return self;
}

- (void) setup {
    
    // load nib
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"OutlookEvents" bundle:nil];
    [nib instantiateWithOwner:self topLevelObjects:nil];
    [self addSubview:contentView];
    
    // more setup
    [self.showAsView setWantsLayer:YES];
    [self.showAsView.layer setCornerRadius:2.0];
    
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(300, NSViewNoIntrinsicMetric);
}

- (void) layout {
    [super layout];
    [contentView setFrame:self.bounds];
}

@end

@interface OutlookNextEventWidget()

@property (retain) NSArray* events;
@property (retain) NSTimer* resetTimer;

@end

@implementation OutlookNextEventWidget

- (void) dealloc
{
    [self.resetTimer invalidate];
}

- (void)commonInit {
    
    // view
    self.customizationLabel = @"Outlook Calendar";
    NextEventsWidgetView *view = [[NextEventsWidgetView alloc] initWithFrame:NSZeroRect];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 8.0;
    view.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    self.view = view;
    
    // busy tap well
    NSGestureRecognizer* busyTapRecognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(onToggleBusy:)];
    busyTapRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    [view.busyWellView addGestureRecognizer:busyTapRecognizer];
    
    // busy tap well
    NSGestureRecognizer* linkTapRecognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(onLink:)];
    linkTapRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    [view.linkWellView addGestureRecognizer:linkTapRecognizer];
    
    // join joins
    [view.joinButton setTarget:self];
    [view.joinButton setAction:@selector(onJoin:)];
    
    // next nexts
    [view.nextButton setTarget:self];
    [view.nextButton setAction:@selector(onNext:)];
    
}

- (void) showEvents:(NSArray*) events {
    self.events = events;
    [self selectEvent];
}

- (void) selectEvent {
    
    // select event to show
    BOOL busyOnly = [[NSUserDefaults standardUserDefaults] boolForKey:@"outlookBusyOnly"];
    self->_event = [OutlookEvent findSoonestEvent:self.events busyOnly:busyOnly];
    
    // and show it
    [self update];
}

- (void) refresh {
    if (self.resetTimer != nil) {
        [self selectEvent];
    } else {
        [self update];
    }
}

- (void) update {
    
    // update
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // basic
        NextEventsWidgetView *view = (NextEventsWidgetView*) self.view;
        [view.timeView setStringValue:SafeStringValue(self.event.startTimeDesc)];
        [view.titleView setStringValue:SafeStringValue(self.event.title)];
        
        // join button
        if (self.event.isCurrent && self.event.joinUrl != nil) {
            if (self.event.isWebEx) {
                [view.joinButtonWidthConstraint setConstant:32];
            } else if (self.event.isTeams) {
                [view.joinButtonWidthConstraint setConstant:32];
                [view.joinButton setImage:[NSImage imageNamed:@"TeamsLogo"]];
                [view.joinButton setBezelStyle:NSBezelStyleRegularSquare];
                [view.joinButton setImagePosition:NSImageOnly];
            } else {
                [view.joinButtonWidthConstraint setConstant:48];
                [view.joinButton setBezelStyle:NSRoundedBezelStyle];
                [view.joinButton setImagePosition:NSNoImage];
            }
        } else {
            [view.joinButtonWidthConstraint setConstant:0];
        }
        
        // show as
        switch (self.event.showAs) {
            case Unknown:
                [view.showAsView.layer setBackgroundColor:[[NSColor grayColor] CGColor]];
                break;
            case Free:
                [view.showAsView.layer setBackgroundColor:[[NSColor whiteColor] CGColor]];
                break;
            case Tentative:
                [view.showAsView.layer setBackgroundColor:[[NSColor colorFromHex:0x7fb2ee] CGColor]];
                break;
            case Busy:
                [view.showAsView.layer setBackgroundColor:[[NSColor colorFromHex:0x0078d4] CGColor]];
                break;
            case OutOfOffice:
                [view.showAsView.layer setBackgroundColor:[[NSColor purpleColor] CGColor]];
                break;
        }
    });
}

- (void) onLink:(id) sender {
    if (self.event.webLink != nil) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self.event.webLink]];
    }
}

- (void) onJoin:(id)sender {
    if (self.event.joinUrl != nil) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self.event.joinUrl]];
    }
}

- (void) onToggleBusy:(id) sender {
    
    // 1st test if it really makes a difference
    BOOL busyOnly = [[NSUserDefaults standardUserDefaults] boolForKey:@"outlookBusyOnly"];
    OutlookEvent* newEvent = [OutlookEvent findSoonestEvent:self.events busyOnly:!busyOnly];
    if (busyOnly == NO || newEvent != self.event) {
        [[NSUserDefaults standardUserDefaults] setBool:!busyOnly forKey:@"outlookBusyOnly"];
        [self selectEvent];
    }
}

- (void) onNext:(id) sender {
    
    // first clear reset timer
    [self.resetTimer invalidate];
    
    // now set it
    self.resetTimer = [NSTimer scheduledTimerWithTimeInterval:RESET_AFTER_USER_NEXT repeats:NO block:^(NSTimer * _Nonnull timer) {
        [self selectEvent];
    }];
    
    // find current and show next
    BOOL showNext = NO;
    for (OutlookEvent* event in self.events) {
        if (showNext) {
            self->_event = event;
            [self update];
            return;
        }
        if (event == self.event) {
            showNext = YES;
        }
    }
    
    // show 1st
    self->_event = [self.events firstObject];
    [self update];
}

@end

