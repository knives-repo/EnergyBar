//
//  OutlookNextEventWidget.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/28/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CustomWidget.h"
#import "OutlookEvent.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OutlookEventWidgetDelegate <NSObject>
- (void) currentEventChanged:(OutlookEvent*) event;
@end

@interface OutlookNextEventWidget : CustomWidget

@property (retain) NSArray* categories;
@property (readonly,retain) OutlookEvent* event;
@property (retain) id<OutlookEventWidgetDelegate> delegate;

- (void) showEvents:(NSArray*) events;
- (void) selectEvent;
- (void) refresh;

@end


NS_ASSUME_NONNULL_END
