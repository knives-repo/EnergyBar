//
//  OutlookCalendarWidget.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/27/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "CustomWidget.h"
#import "OutlookEvent.h"
#import "OutlookNextEventWidget.h"

NS_ASSUME_NONNULL_BEGIN

@interface OutlookCalendarWidget : CustomMultiWidget<OutlookEventWidgetDelegate>
- (void)setPressTarget:(id)target action:(SEL)action;
- (void)updateReloadingAccount:(BOOL) reloadAccount reloadingEvents:(BOOL) reloadEvents;
@end

NS_ASSUME_NONNULL_END
