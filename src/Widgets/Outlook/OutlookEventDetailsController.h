//
//  OutlookEventDetailsController.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/30/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OutlookEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface OutlookEventDetailsController : NSViewController

@property (assign) IBOutlet NSView *showAsView;
@property (assign) IBOutlet NSTextField *timeView;
@property (assign) IBOutlet NSTextField *titleView;
@property (assign) IBOutlet NSTextField *organizerView;

- (id) initWithEvent:(OutlookEvent*) event;

@end

NS_ASSUME_NONNULL_END
