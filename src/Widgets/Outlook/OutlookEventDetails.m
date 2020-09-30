//
//  OutlookEventDetail.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/29/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "OutlookEventDetails.h"
#import "OutlookUtils.h"

@implementation OutlookEventDetails

- (id) initWithFrame:(NSRect)frameRect forEvent:(OutlookEvent*) event
{
    // init
    self = [super initWithFrame:frameRect];
    
    // load xib
    NSNib *nib = [[[NSNib alloc] initWithNibNamed:@"OutlookEventDetails" bundle:nil] autorelease];
    if ([nib instantiateWithOwner:self topLevelObjects:nil] == FALSE) {
        return nil;
    }

    // add view
    //self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    //self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:self.contentView];
    //[self setFrame:self.contentView.frame];

    // update
    [self.timeView setStringValue:event.timingDesc];
    [self.titleView setStringValue:event.title];
    [self.organizerView setStringValue:event.organizerName];
    
    [self.showAsView setWantsLayer:YES];
    [self.showAsView.layer setCornerRadius:4];
    [OutlookUtils styleShowAsIndicator:self.showAsView forEvent:event];
            
    // done
    return self;

}

@end
