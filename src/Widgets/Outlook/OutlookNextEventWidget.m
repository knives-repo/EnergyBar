//
//  OutlookNextEventWidget.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/28/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import "OutlookNextEventWidget.h"
#import "NSRunningApplication+Utils.h"
#import "OutlookEventDetailsController.h"
#import "BezelWindow.h"
#import "NSColor+Hex.h"
#import "OutlookUtils.h"
#import "Outlook.h"
#import "KeyEvent.h"

#define RESET_AFTER_USER_NEXT 5

@interface NextEventsWidgetView : NSView
@end

@implementation NextEventsWidgetView

- (NSSize)intrinsicContentSize
{
    // get size with default value
    id size = [[NSUserDefaults standardUserDefaults] objectForKey:@"outlookWidgetSize"];
    
    // width
    int width = 250;
    if (size != nil) {
        if ([size intValue] == 0) {
            width = 200;
        } else if ([size intValue] == 2) {
            width = 300;
        } else if ([size intValue] == 3) {
            width = NSViewNoIntrinsicMetric;
        }
    }
    
    // return
    return NSMakeSize(width, NSViewNoIntrinsicMetric);
}

@end

@interface NextEventsWidgetController : NSViewController

@property (assign) CustomWidget *widget;
@property (assign) IBOutlet NSView *busyWellView;
@property (assign) IBOutlet NSView *linkWellView;
@property (assign) IBOutlet NSView *showAsView;
@property (assign) IBOutlet NSTextField *timeView;
@property (assign) IBOutlet NSTextField *titleView;
@property (assign) IBOutlet NSButton *joinButton;
@property (assign) IBOutlet NSButton *nextButton;
@property (assign) IBOutlet NSLayoutConstraint *joinButtonWidthConstraint;

@end

@implementation NextEventsWidgetController

- (void) viewDidLoad
{
    // layer for ourself
    [self.view setWantsLayer:YES];
    [self.view.layer setCornerRadius: 8.0];
    [self.view.layer setBackgroundColor:[[NSColor colorWithWhite:0.0 alpha:0.5] CGColor]];

    // more setup
    [self.showAsView setWantsLayer:YES];
    [self.showAsView.layer setCornerRadius:4.0];
    
}

- (void) viewWillAppear
{
    [self.widget viewWillAppear];
}

@end

@interface OutlookNextEventWidget()

@property (retain) NSRunningApplication* runningApplication;
@property (retain) NextEventsWidgetController* controller;
@property (retain) NSArray* events;
@property (retain) NSTimer* resetTimer;
@property (assign) NSPoint startSlidePoint;
@property (assign) BOOL scrolled;
@property (assign) BOOL joinTeams;

@end

@implementation OutlookNextEventWidget

- (void) dealloc
{
    [self.resetTimer invalidate];
    [super dealloc];
}

- (void)commonInit
{
    // label
    self.customizationLabel = @"Outlook Calendar";
    
    // controller
    self.controller = [[NextEventsWidgetController alloc] initWithNibName:@"OutlookEvents" bundle:nil];
    self.controller.widget = self;
    self.viewController = self.controller;
    
}

- (void) viewWillAppear {

    // busy tap well
    NSGestureRecognizer* busyTapRecognizer = [[[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(onToggleBusy:)] autorelease];
    busyTapRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    [self.controller.busyWellView addGestureRecognizer:busyTapRecognizer];
    
    // busy tap well
    NSPressGestureRecognizer* textPressRecognizer = [[[NSPressGestureRecognizer alloc] initWithTarget:self action:@selector(onTextPress:)] autorelease];
    textPressRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    textPressRecognizer.minimumPressDuration = 0;
    [self.controller.linkWellView addGestureRecognizer:textPressRecognizer];
    
    // join joins
    [self.controller.joinButton setTarget:self];
    [self.controller.joinButton setAction:@selector(onJoin:)];
    
    // next nexts
    [self.controller.nextButton setTarget:self];
    [self.controller.nextButton setAction:@selector(onNext:)];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(didActivateApplication:)
        name:NSWorkspaceDidActivateApplicationNotification
        object:nil];

}

- (void)viewDidDisappear
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self];
}

- (void) showEvents:(NSArray*) events
{
    self.events = events;
    [self selectEvent];
}

- (void) selectEvent
{
    
    // select event to show
    BOOL busyOnly = [[NSUserDefaults standardUserDefaults] boolForKey:@"outlookBusyOnly"];
    self->_event = [OutlookEvent findSoonestEvent:self.events busyOnly:busyOnly];
    [self.delegate currentEventChanged:self.event];
    
    // and show it
    [self update];
}

- (void) refresh
{
    if (self.resetTimer == nil || self.resetTimer.isValid == NO) {
        [self selectEvent];
    } else {
        [self update];
    }
}

- (void) update
{
    // update
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // basic
        NextEventsWidgetController *controller = (NextEventsWidgetController*) self.viewController;
        [controller.timeView setStringValue:SafeStringValue(self.event.timingDesc)];
        [controller.titleView setStringValue:SafeStringValue(self.event.title)];
        
        // join button
        if (self.event.canBeJoined == NO || self.event.joinUrl == nil) {
            
            // hide the join button
            [controller.joinButtonWidthConstraint setConstant:0];

        } else {
            
            // image or not
            NSImage* icon = nil;
            if (self.event.isWebEx) {
                icon = [NSImage imageNamed:@"WebexLogo"];
            } else if (self.event.isTeams) {
                icon = [NSImage imageNamed:@"TeamsLogo"];
            } else if (self.event.isSkype) {
                icon = [NSImage imageNamed:@"SkypeLogo"];
            } else if (self.event.isGoogleMeet) {
                icon = [NSImage imageNamed:@"GoogleMeetLogo"];
            } else if (self.event.isZoom) {
                icon = [NSImage imageNamed:@"ZoomLogo"];
            }

            // update
            if (icon != nil) {
                [controller.joinButton setBezelStyle:NSBezelStyleRegularSquare];
                [controller.joinButton setTransparent:YES];
                [controller.joinButton setImage:icon];
                [controller.joinButton setImagePosition:NSImageOnly];
                [controller.joinButtonWidthConstraint setConstant:32];
            } else {
                [controller.joinButton setBezelStyle:NSBezelStyleRounded];
                [controller.joinButton setTransparent:NO];
                [controller.joinButton setImagePosition:NSNoImage];
                [controller.joinButtonWidthConstraint setConstant:40];

                // text switches to a gray so force it to white with attibuted title
                NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[controller.joinButton attributedTitle]];
                [colorTitle addAttribute:NSForegroundColorAttributeName
                                   value:[NSColor whiteColor]
                                   range:NSMakeRange(0, controller.joinButton.attributedTitle.length)];
                [controller.joinButton setAttributedTitle:colorTitle];
            }
        }
        
        // show as
        [OutlookUtils styleShowAsIndicator:controller.showAsView forEvent:self.event];
        
        // update
        [controller.view setNeedsDisplay:YES];
    
    });
}

- (void) onLink:(id) sender
{
    if (self.event.webLink != nil) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self.event.webLink]];
    }
}

- (void) onJoin:(id)sender
{
    if (self.event.joinUrl != nil) {
        
        // try direct first
        NSString* joinUrl = self.event.directJoinUrl;
        NSURL* appURL = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:[NSURL URLWithString:joinUrl]];
        if (appURL == nil) {
        
            // fallback
            joinUrl = self.event.joinUrl;
        
        } else {
            
            // auto-join
            if (self.event.isTeams) {
                self.joinTeams = YES;
            }
       
        }
        
        // if frontmost before opening
        BOOL isActive = [[[NSWorkspace sharedWorkspace] frontmostApplication] isMicrosoftTeams];
        
        // now open it
        //NSLog(@"%@", joinUrl);
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:joinUrl]];
        
        // application switch will not be triggered so let's do it ourselves
        if (isActive) {
            [self didActivateApplication:nil];
        }
    }
}

- (void) onToggleBusy:(id) sender
{
    // update
    BOOL busyOnly = ![[NSUserDefaults standardUserDefaults] boolForKey:@"outlookBusyOnly"];
    [[NSUserDefaults standardUserDefaults] setBool:busyOnly forKey:@"outlookBusyOnly"];
    [self selectEvent];
    
    // nofity
    [BezelWindow showWithMessage:busyOnly ? @"Showing accepted events only" : @"Showing all events"];

}

- (void) onNext:(id) sender
{
    if ([self navigate:1 cycle:YES showDetail:NO] == NO) {
        [BezelWindow showWithMessage:@"No more events. For now!"];
    }
}

- (BOOL) navigate:(int) direction cycle:(BOOL) cycle showDetail:(BOOL) showDetail
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
                return FALSE;
            }
            curr = 0;
        }
        if (curr == -1) {
            if (cycle == NO) {
                return FALSE;
            }
            curr = self.events.count - 1;
        }
        if (curr == index) {
            // nothing found
            return FALSE;
        }

        // now get info
        OutlookEvent* event = [self.events objectAtIndex:curr];
        if (event.isEnded == NO && (busyOnly == NO || event.showAs == ShowAsBusy)) {
            if (showDetail) {
                [self showEventDetail:event];
            }
            self->_event = event;
            [self update];
            return TRUE;
        }
        
        // increment
        curr += direction;
    }
    
}

- (void)showEventDetail:(OutlookEvent*) event
{
    OutlookEventDetailsController* controller = [[OutlookEventDetailsController alloc] initWithEvent:event];
    [BezelWindow showWithView:controller.view inDarkMode:YES];
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
    // store point and reset
    NSPoint point = [recognizer locationInView:self.controller.view];
    self.startSlidePoint = point;
    self.scrolled = NO;
}

- (void)shortPressChanged:(NSGestureRecognizer *)recognizer
{
    // get new point
    NSPoint point = [recognizer locationInView:self.controller.view];
    int delta = point.x - self.startSlidePoint.x;
    
    // invert?
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"outlookInvertScrubDirection"]) {
        delta = -delta;
    }

    // check
    if (abs(delta) > 10) {
        int direction = (delta < 0 ? 1 : -1);
        if ([self navigate:direction cycle:NO showDetail:YES] == NO) {
            if (self.scrolled == NO) {
                [self notifyScrollEnd:(direction == -1) ? @"No previous event" :@"No next event"];
            }
        }
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

- (void)notifyScrollEnd:(NSString*) message {
    OutlookEvent* event = [[OutlookEvent alloc] init];
    [event setTitle:message];
    [event setImportance:ImportanceHigh];
    [event setShowAs:ShowAsBusy];
    [self showEventDetail:event];
}

- (void)didActivateApplication:(id) sender
{
    // update
    NSRunningApplication* runningApplication = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if ([runningApplication isMicrosoftTeams]) {
        if (self.joinTeams) {

            // wait time depends on if this is being launched or not
            BOOL isLaunching = (runningApplication.finishedLaunching == NO);
            
            // wait some time
            [NSTimer scheduledTimerWithTimeInterval:(isLaunching ? 7.5 : 1.5) repeats:NO block:^(NSTimer * _Nonnull timer) {
                // enter
                PostKeyPress(36, 0);
            }];
            
            // done
            self.joinTeams = NO;

        }
    }

}

@end

