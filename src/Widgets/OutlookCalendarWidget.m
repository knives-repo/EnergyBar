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

#define FETCH_CALENDAR_EVERY_SECONDS 5*60

@interface NextEventsWidgetView : NSView

@property (assign) IBOutlet NSView *contentView;
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
    [self.showAsView.layer setBackgroundColor:[[NSColor blueColor] CGColor]];
    
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(250, NSViewNoIntrinsicMetric);
}

- (void) layout {
    [super layout];
    [contentView setFrame:self.bounds];
}

@end


@interface NextEventWidget : CustomWidget
@property (retain) OutlookEvent* event;
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
    
    // more init
    [view.joinButton setTarget:self];
    [view.joinButton setAction:@selector(onJoin:)];
    
}

- (void) showEvent:(OutlookEvent*) event {
    self.event = event;
    [self update];
}

- (void) update {
    dispatch_async(dispatch_get_main_queue(), ^{
        NextEventsWidgetView *view = (NextEventsWidgetView*) self.view;
        [view.timeView setStringValue:self.event.startTimeDesc];
        [view.titleView setStringValue:self.event.title];
        [view.joinButtonWidthConstraint setConstant:(self.event.isCurrent ? 48 : 0)];
    });
}

- (void) onJoin:(id) sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self.event.joinUrl]];
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
    [self addWidget:[[ImageTileWidget alloc] initWithIdentifier:@"_OutlookNoSignin"
                                             customizationLabel:@"Outlook Calendar"
                                                          title:@"No connection"
                                                           icon:[NSImage imageNamed:NSImageNameUserAccounts]]];
    
    // no event
    [self addWidget:[[ImageTileWidget alloc] initWithIdentifier:@"_OutlookNoEvents"
                                             customizationLabel:@"Outlook Calendar"
                                                          title:@"No events"]];
    
    // add widgets
    self.nextEventWidget = [[[NextEventWidget alloc] initWithIdentifier:@"_OutlookNextEvents"] autorelease];
    [self addWidget:self.nextEventWidget];
    
    // init outlook
    self.outlook = [[Outlook alloc] init];
        
}

- (void)tapAction:(id)sender {
    
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
                OutlookEvent* event = [OutlookEvent findSoonestEvent:events];
                if (event != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setActiveIndex:2];
                        [self.nextEventWidget showEvent:event];
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

@end
