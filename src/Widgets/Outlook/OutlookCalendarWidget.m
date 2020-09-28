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

#define FETCH_CALENDAR_EVERY_SECONDS 5*60

@interface OutlookCalendarWidget()
@property (retain) OutlookNextEventWidget* nextEventWidget;
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
    self.nextEventWidget = [[[OutlookNextEventWidget alloc] initWithIdentifier:@"_OutlookNextEvent"] autorelease];
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
            [self.nextEventWidget refresh];
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
                self.lastFetch = [NSDate date];
                NSArray* jsonEvents = [jsonCalendar objectForKey:@"value"];
                NSArray* events = [OutlookEvent listFromJson:jsonEvents];
                #if DUMP
                    for (OutlookEvent* event in events) {
                        NSLog(@"%@", event);
                    }
                #endif
                [self.nextEventWidget showEvents:[events sortedArrayUsingSelector:@selector(compare:)]];
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
        [self.nextEventWidget selectEvent];
    }
}

@end
