//
//  OutlookNextEventWidget.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/28/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "OutlookNextEventWidget.h"
#import "BezelWindow.h"
#import "NSColor+Hex.h"
#import "Outlook.h"

#define RESET_AFTER_USER_NEXT 5

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
    NSNib *nib = [[[NSNib alloc] initWithNibNamed:@"OutlookEvents" bundle:nil] autorelease];
    [nib instantiateWithOwner:self topLevelObjects:nil];
    [self addSubview:contentView];
    
    // more setup
    [self.showAsView setWantsLayer:YES];
    [self.showAsView.layer setCornerRadius:4.0];
    
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(280, NSViewNoIntrinsicMetric);
}

- (void) layout {
    [super layout];
    [contentView setFrame:self.bounds];
}

@end

@interface OutlookNextEventWidget()

@property (retain) NSArray* events;
@property (retain) NSTimer* resetTimer;

@property (assign) NSPoint startSlidePoint;
@property (assign) BOOL scrolled;

@end

@implementation OutlookNextEventWidget

- (void) dealloc
{
    [self.resetTimer invalidate];
    [super dealloc];
}

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
    NSPressGestureRecognizer* textPressRecognizer = [[[NSPressGestureRecognizer alloc] initWithTarget:self action:@selector(onTextPress:)] autorelease];
    textPressRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    textPressRecognizer.minimumPressDuration = 0;
    [view.linkWellView addGestureRecognizer:textPressRecognizer];
    
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
    if (self.resetTimer == nil || self.resetTimer.isValid == NO) {
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
        [view.timeView setStringValue:SafeStringValue(self.event.timingDesc)];
        [view.titleView setStringValue:SafeStringValue(self.event.title)];
        
        // join button
        if (self.event.isCurrent == NO || self.event.joinUrl == nil) {
            
            // hide the join button
            [view.joinButtonWidthConstraint setConstant:0];

        } else {
            
            // image or not
            NSImage* icon = nil;
            if (self.event.isWebEx) {
                icon = [NSImage imageNamed:@"WebexLogo"];
            } else if (self.event.isTeams) {
                icon = [NSImage imageNamed:@"TeamsLogo"];
            }
            
            // update
            if (icon != nil) {
                [view.joinButton setBezelStyle:NSBezelStyleRegularSquare];
                [view.joinButton setTransparent:YES];
                [view.joinButton setImage:icon];
                [view.joinButton setImagePosition:NSImageOnly];
                [view.joinButtonWidthConstraint setConstant:32];
            } else {
                [view.joinButton setBezelStyle:NSBezelStyleRounded];
                [view.joinButton setTransparent:NO];
                [view.joinButton setImagePosition:NSNoImage];
                [view.joinButtonWidthConstraint setConstant:40];

                // text switches to a gray so force it to white with attibuted title
                NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[view.joinButton attributedTitle]];
                [colorTitle addAttribute:NSForegroundColorAttributeName
                                   value:[NSColor whiteColor]
                                   range:NSMakeRange(0, view.joinButton.attributedTitle.length)];
                [view.joinButton setAttributedTitle:colorTitle];
            }
        }
        
        // show as
        switch (self.event.showAs) {
            case ShowAsUnknown:
                [view.showAsView.layer setBackgroundColor:[[NSColor grayColor] CGColor]];
                break;
            case ShowAsFree:
                [view.showAsView.layer setBackgroundColor:[[NSColor whiteColor] CGColor]];
                break;
            case ShowAsTentative:
                [view.showAsView.layer setBackgroundColor:[[NSColor colorFromHex:0x7fb2ee] CGColor]];
                break;
            case ShowAsBusy:
                [view.showAsView.layer setBackgroundColor:[[self colorForBusyEvent:self.event] CGColor]];
                break;
            case ShowAsOutOfOffice:
                [view.showAsView.layer setBackgroundColor:[[NSColor purpleColor] CGColor]];
                break;
        }
    });
}

- (NSColor*) colorForBusyEvent:(OutlookEvent*) event {
    
    // importance
    if (event.importance == ImportanceHigh || (event.categories != nil && [event.categories containsObject:@"Important"])) {
        return [NSColor redColor];
    }
    
    // default
    if (self.categories != nil && event.categories != nil && event.categories.count > 0) {

        // 1st category
        NSString* category = [event.categories firstObject];
        
        // iterate
        for (NSDictionary* categoryDefinition in self.categories) {
            if ([[categoryDefinition objectForKey:@"displayName"] isEqualToString:category]) {
                NSString* color = [categoryDefinition objectForKey:@"color"];
                NSDictionary* presetColors = [Outlook presetColors];
                if ([[presetColors allKeys] containsObject:color]) {
                    return [presetColors objectForKey:color];
                }
            }
        }

    }
    
    // default
    return [NSColor colorFromHex:0x0078d4];

    
}

- (void) onLink:(id) sender {
    if (self.event.webLink != nil) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self.event.webLink]];
    }
}

- (void) onJoin:(id)sender {
    if (self.event.joinUrl != nil) {
        
        // try direct first
        NSString* joinUrl = self.event.directJoinUrl;
        NSURL* appURL = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:[NSURL URLWithString:joinUrl]];
        if (appURL == nil) {
            joinUrl = self.event.joinUrl;
        }
        
        // now open it
        NSLog(@"%@", joinUrl);
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:joinUrl]];
    }
}

- (void) onToggleBusy:(id) sender {
    
    BOOL busyOnly = [[NSUserDefaults standardUserDefaults] boolForKey:@"outlookBusyOnly"];
    [[NSUserDefaults standardUserDefaults] setBool:!busyOnly forKey:@"outlookBusyOnly"];
    [self selectEvent];

}

- (void) onNext:(id) sender {
    [self navigate:1 cycle:YES showTitle:NO];
}

- (void) navigate:(int) direction cycle:(BOOL) cycle showTitle:(BOOL) showTitle
{
    
    // first clear reset timer
    [self.resetTimer invalidate];
    
    // now set it
    self.resetTimer = [NSTimer scheduledTimerWithTimeInterval:RESET_AFTER_USER_NEXT repeats:NO block:^(NSTimer * _Nonnull timer) {
        [self selectEvent];
    }];
    
    // find current event
    BOOL busyOnly = [[NSUserDefaults standardUserDefaults] boolForKey:@"outlookBusyOnly"];
    long index = [self.events indexOfObject:self.event];
    long curr = index + direction;
    while (true) {
        
        // check
        if (curr > (long) self.events.count - 1) {
            if (cycle == NO) {
                return;
            }
            curr = 0;
        }
        if (curr == -1) {
            if (cycle == NO) {
                return;
            }
            curr = self.events.count - 1;
        }
        if (curr == index) {
            // nothing found
            return;
        }

        // now get info
        OutlookEvent* event = [self.events objectAtIndex:curr];
        if (event.isEnded == NO && (busyOnly == NO || event.showAs == ShowAsBusy)) {
            //[BezelWindow showWithMessage:[NSString stringWithFormat:@"%@\n%@", event.startTimeDesc, event.title]];
            [BezelWindow showWithMessage:event.title];
            self->_event = event;
            [self update];
            return;
        }
        
        // increment
        curr += direction;
    }
    
}

- (void)onTextPress:(NSGestureRecognizer *)recognizer
{
    switch (recognizer.state)
    {
    case NSGestureRecognizerStateBegan:
        [self shortPressBegan:recognizer];
        break;
    case NSGestureRecognizerStateChanged:
        [self shortPressChanged:recognizer];
        break;
    case NSGestureRecognizerStateEnded:
        [self shortPressEnded:recognizer];
        break;
    default:
        return;
    }
}

- (void)shortPressBegan:(NSGestureRecognizer *)recognizer
{
    NextEventsWidgetView *view = (NextEventsWidgetView*) self.view;
    NSPoint point = [recognizer locationInView:view.contentView];
    self.startSlidePoint = point;
    self.scrolled = NO;
}

- (void)shortPressChanged:(NSGestureRecognizer *)recognizer
{
    // get new point
    NextEventsWidgetView *view = (NextEventsWidgetView*) self.view;
    NSPoint point = [recognizer locationInView:view.contentView];
    int delta = point.x - self.startSlidePoint.x;

    // check
    if (abs(delta) > 10) {
        [self navigate:(delta < 0 ? -1 : 1) cycle:NO showTitle:YES];
        self.startSlidePoint = point;
        self.scrolled = YES;
    }
}

- (void)shortPressEnded:(NSGestureRecognizer *)recognizer
{
    if (self.scrolled == NO) {
        [self onLink:recognizer];
    }
}

@end

