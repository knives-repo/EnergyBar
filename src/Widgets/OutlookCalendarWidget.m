//
//  OutlookCalendarWidget.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/27/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "OutlookCalendarWidget.h"
#import "ImageTileWidget.h"
#import "OutlookEvent.h"
#import "Outlook.h"
#import "NSColor+Hex.h"

#define FETCH_CALENDAR_EVERY_SECONDS 5*60

@interface NextEventsWidgetView : NSView

@property (assign) IBOutlet NSView *contentView;
@property (assign) IBOutlet NSView *busyWellView;
@property (assign) IBOutlet NSView *linkWellView;
@property (assign) IBOutlet NSView *showAsView;
@property (assign) IBOutlet NSTextField *timeView;
@property (assign) IBOutlet NSTextField *titleView;
@property (assign) IBOutlet NSButton *joinButton;
@property (assign) IBOutlet NSLayoutConstraint *joinButtonWidthConstraint;

@end

@implementation NextEventsWidgetView

@synthesize contentView;

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    [self setup];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    [super initWithCoder:coder];
    [self setup];
    return self;
}

- (void) setup {
    
    // load nib
    NSNib *nib = [[[NSNib alloc] initWithNibNamed:@"OutlookEvents" bundle:nil] autorelease];
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

@interface NextEventWidget : CustomWidget

@property (retain) NSArray* events;
@property (readonly,retain) OutlookEvent* event;

- (void) update;

@end

@implementation NextEventWidget

- (void)commonInit {
    
    // view
    self.customizationLabel = @"Outlook Calendar";
    NextEventsWidgetView *view = [[[NextEventsWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 8.0;
    view.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    self.view = view;
    
    // busy tap well
    NSGestureRecognizer* busyTapRecognizer = [[[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(onToggleBusy:)] autorelease];
    busyTapRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    [view.busyWellView addGestureRecognizer:busyTapRecognizer];
    
    // busy tap well
    NSGestureRecognizer* linkTapRecognizer = [[[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(onLink:)] autorelease];
    linkTapRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    [view.linkWellView addGestureRecognizer:linkTapRecognizer];
    
    // join joins
    [view.joinButton setTarget:self];
    [view.joinButton setAction:@selector(onJoin:)];
    
}

- (void) showEvents:(NSArray*) events {
    self.events = events;
    [self update];
}

- (void) update {

    // select event to show
    BOOL busyOnly = [[NSUserDefaults standardUserDefaults] boolForKey:@"outlookBusyOnly"];
    self->_event = [OutlookEvent findSoonestEvent:self.events busyOnly:busyOnly];

    // update
    dispatch_async(dispatch_get_main_queue(), ^{

        // basic
        NextEventsWidgetView *view = (NextEventsWidgetView*) self.view;
        [view.timeView setStringValue:self.event.startTimeDesc];
        [view.titleView setStringValue:self.event.title];
        
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
    if (newEvent != self.event) {
        [[NSUserDefaults standardUserDefaults] setBool:!busyOnly forKey:@"outlookBusyOnly"];
        [self update];
    }
}

@end

@interface OutlookCalendarWidget()
@property (retain) NextEventWidget* nextEventWidget;
@property (retain) NSTimer* refreshTimer;
@property (retain) Outlook* outlook;
@property (retain) NSDate* lastFetch;
@end

@implementation OutlookCalendarWidget

- (void)commonInit {
    
    // no connection
    [self addWidget:[[[ImageTileWidget alloc] initWithIdentifier:@"_OutlookNoSignin"
                                             customizationLabel:@"Outlook Calendar"
                                                          title:@"No connection"
                                                           icon:[NSImage imageNamed:NSImageNameUserAccounts]] autorelease]];
    
    // no event
    [self addWidget:[[[ImageTileWidget alloc] initWithIdentifier:@"_OutlookNoEvents"
                                             customizationLabel:@"Outlook Calendar"
                                                          title:@"No events"] autorelease]];
    
    // add widgets
    self.nextEventWidget = [[[NextEventWidget alloc] initWithIdentifier:@"_OutlookNextEvent"] autorelease];
    [self addWidget:self.nextEventWidget];
    
    // init outlook
    self.outlook = [[[Outlook alloc] init] autorelease];
        
}

- (void)tapAction:(id)sender {
    
    switch (self.activeIndex) {
        case 0:
            break;
            
        case 1:
            break;
            
        case 2:
            break;
    }
    
}

- (void)viewWillAppear {
    [NSTimer scheduledTimerWithTimeInterval:15 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (self.lastFetch == nil || fabs([self.lastFetch timeIntervalSinceNow]) > FETCH_CALENDAR_EVERY_SECONDS) {
            [self loadEvents];
        } else {
            [self.nextEventWidget update];
        }
    }];
    [self loadEvents];
}

- (void)loadEvents {
    [self.outlook loadCurrentAccount:^{
        if (self.outlook.currentAccount == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setActiveIndex:0];
            });
        } else {
            [self.outlook getCalendarEvents:^(NSDictionary * jsonCalendar) {
                self.lastFetch = [[NSDate alloc] init];
                NSArray* jsonEvents = [jsonCalendar objectForKey:@"value"];
                NSArray* events = [OutlookEvent listFromJson:jsonEvents];
                [self.nextEventWidget showEvents:events];
                if (self.nextEventWidget.event != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setActiveIndex:2];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setActiveIndex:1];
                    });
                }
            }];
        }
    }];
}

- (void)viewWillDisappear {
    [self.refreshTimer invalidate];
}

- (void)update {
    if (self.activeIndex == 2) {
        [self.nextEventWidget update];
    }
}

@end
