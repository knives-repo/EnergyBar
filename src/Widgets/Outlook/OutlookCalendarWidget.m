//
//  OutlookCalendarWidget.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/27/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "OutlookCalendarWidget.h"
#import "OutlookNextEventWidget.h"
#import "ImageTileWidget.h"
#import "OutlookEvent.h"
#import "Outlook.h"

#define DUMP 1

#define SIGNIN_INDEX 0
#define LOADING_INDEX 1
#define EMPTY_INDEX 2
#define EVENT_INDEX 3

#define FETCH_CALENDAR_EVERY_SECONDS 5*60

@interface OutlookCalendarWidget()
@property (retain) OutlookNextEventWidget* nextEventWidget;
@property (retain) NSTimer* refreshTimer;
@property (retain) Outlook* outlook;
@property (retain) NSDate* lastFetch;
@property (retain) id target;
@property (assign) SEL action;
@end

@implementation OutlookCalendarWidget

- (void)commonInit {
    
    // no connection
    [self addWidget:[[[ImageTileWidget alloc] initWithIdentifier:@"_OutlookNoSignin"
                                             customizationLabel:@"Outlook Calendar"
                                                          title:@"Tap to setup your Microsoft account"
                                                           icon:[NSImage imageNamed:NSImageNameUserAccounts]] autorelease]];
    
    // loading
    [self addWidget:[[[ImageTileWidget alloc] initWithIdentifier:@"_OutlookLoading"
                                             customizationLabel:@"Outlook Calendar"
                                                          title:@"Loading your calendar..."
                                                           icon:[NSImage imageNamed:@"ActivityIndicator"]] autorelease]];
    
    // no event
    [self addWidget:[[[ImageTileWidget alloc] initWithIdentifier:@"_OutlookNoEvents"
                                             customizationLabel:@"Outlook Calendar"
                                                          title:@"No events"
                                                            icon:[NSImage imageNamed:NSImageNameMenuOnStateTemplate]] autorelease]];
    
    // add widgets
    self.nextEventWidget = [[[OutlookNextEventWidget alloc] initWithIdentifier:@"_OutlookNextEvent"] autorelease];
    [self addWidget:self.nextEventWidget];
    
    // init outlook
    self.outlook = [[[Outlook alloc] init] autorelease];
        
}

- (void)setPressTarget:(id)target action:(SEL)action
{
    self.target = target;
    self.action = action;
}

- (void)tapAction:(id)sender {
    
    switch (self.activeIndex) {
        case SIGNIN_INDEX:
            [self.target performSelector:self.action withObject:[NSNumber numberWithInt:1]];
            break;
            
        case LOADING_INDEX:
            break;
            
        case EMPTY_INDEX:
            break;
            
        case EVENT_INDEX:
            break;
    }
    
}

- (void)viewWillAppear {
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:15 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (self.lastFetch == nil || fabs([self.lastFetch timeIntervalSinceNow]) > FETCH_CALENDAR_EVERY_SECONDS) {
            [self loadEvents];
        } else {
            [self.nextEventWidget refresh];
        }
    }];
    [self loadEvents];
}

- (void)loadEvents {
    
    [self.outlook loadCurrentAccount:^{

        // need an account
        if (self.outlook.currentAccount == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setActiveIndex:SIGNIN_INDEX];
            });
            return;
        }
        
        // while loading
        if (self.activeIndex != EVENT_INDEX) {
            [self setActiveIndex:LOADING_INDEX];
        }
        
        // load categories
        //[self.outlook getCategories:^(NSDictionary * jsonCategories) {
        //    NSLog(@"%@", jsonCategories);
        //    [self.nextEventWidget setCategories:[jsonCategories objectForKey:@"value"]];
        //}];
        
        // load events
        [self.outlook getCalendarEvents:^(NSDictionary * jsonCalendar) {
            self.lastFetch = [NSDate date];
            NSArray* jsonEvents = [jsonCalendar objectForKey:@"value"];
            NSArray* events = [OutlookEvent listFromJson:jsonEvents];
            [self.nextEventWidget showEvents:[events sortedArrayUsingSelector:@selector(compare:)]];
            #if DUMP
                for (OutlookEvent* event in events) {
                    NSLog(@"%@", event);
                }
            #endif
            if (self.nextEventWidget.event != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActiveIndex:EVENT_INDEX];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActiveIndex:EMPTY_INDEX];
                });
            }
        }];

    }];
}

- (void)viewWillDisappear {
    [self.refreshTimer invalidate];
}

- (void)updateReloadingAccount:(BOOL) reloadAccount {

    // simple: basic config change
    if (reloadAccount == NO) {
        
        if (self.activeIndex == EVENT_INDEX) {
            [self.nextEventWidget selectEvent];
        }
        
    } else {
        
        // re-fetch everything
        self.outlook = [[[Outlook alloc] init] autorelease];
        [self loadEvents];
        
    }

}

@end
