//
//  OutlookEventDetail.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/29/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OutlookEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface OutlookEventDetails : NSView

@property (assign) IBOutlet NSView *contentView;
@property (assign) IBOutlet NSView *showAsView;
@property (assign) IBOutlet NSTextField *timeView;
@property (assign) IBOutlet NSTextField *titleView;
@property (assign) IBOutlet NSTextField *organizerView;

- (id) initWithFrame:(NSRect)frameRect forEvent:(OutlookEvent*) event;

@end

NS_ASSUME_NONNULL_END
