//
//  OutlookCalendarWidget.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/27/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "OutlookCalendarWidget.h"
#import "Outlook.h"

@interface NextEventsWidgetView : NSView

@property (assign) IBOutlet NSView *contentView;
@property (assign) IBOutlet NSView *showAsView;
@property (assign) IBOutlet NSTextField *timeView;
@property (assign) IBOutlet NSTextField *titleView;
@property (assign) IBOutlet NSButton *joinButton;

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

- (void) showEvent:(NSDictionary*) jsonEvent {
    self.event = [[OutlookEvent alloc] initWithJson:jsonEvent];
    [self update];
}

- (void) update {
    dispatch_async(dispatch_get_main_queue(), ^{
        NextEventsWidgetView *view = (NextEventsWidgetView*) self.view;
        [view.timeView setStringValue:self.event.startTimeDesc];
        [view.titleView setStringValue:self.event.title];
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
@end

@implementation OutlookCalendarWidget

- (void)commonInit {

    // add widgets
    self.nextEventWidget = [[[NextEventWidget alloc] initWithIdentifier:@"_NextEvents"] autorelease];
    [self addWidget:self.nextEventWidget];

    // init outlook
    self.outlook = [[Outlook alloc] init];
}

- (void)viewWillAppear {
    [NSTimer timerWithTimeInterval:5 repeats:YES block:^(NSTimer * _Nonnull timer) {
            [self loadEvents];
    }];
    [self loadEvents];
}

- (void)loadEvents {
    [self.outlook loadCurrentAccount:^{
            if (self.outlook.currentAccount == nil) {
                
            } else {
                [self.outlook getCalendarEvents:^(NSDictionary * jsonCalendar) {
                    NSArray* events = [jsonCalendar objectForKey:@"value"];
                    if (events != nil && events.count > 0) {
                        NSDictionary* event = [events objectAtIndex:0];
                        [self.nextEventWidget showEvent:event];
                    }
                }];
            }
    }];
}

- (void)viewWillDisappear {
    [self.refreshTimer invalidate];
}

@end
