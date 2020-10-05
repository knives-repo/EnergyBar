//
//  OutlookEventDetailsController.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/30/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import "OutlookEventDetailsController.h"
#import "OutlookUtils.h"

@interface OutlookEventDetailsController()
@property (retain) OutlookEvent* event;
@end

@implementation OutlookEventDetailsController

- (id) initWithEvent:(OutlookEvent*) event
{
    self = [super initWithNibName:@"OutlookEventDetails" bundle:nil];
    self.event = event;
    return self;
}

- (void) viewDidLoad {

    // show as
    [self.showAsView setWantsLayer:YES];
    [self.showAsView.layer setCornerRadius:4];
    [OutlookUtils styleShowAsIndicator:self.showAsView forEvent:self.event];

    // update
    [self.timeView setStringValue:SafeStringValue(self.event.timingDesc)];
    [self.titleView setStringValue:SafeStringValue(self.event.title)];
    [self.organizerView setStringValue:SafeStringValue(self.event.organizerName)];
    
}

@end
