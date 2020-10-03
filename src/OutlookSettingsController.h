//
//  OutlookSettingsController.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/3/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OutlookSettingsDelegate
- (void)outlookAccountUpdated;
- (void)outlookSettingsUpdated:(BOOL) reloadEvents;
@end

@interface CategoryColorPopUpButtonCell : NSPopUpButtonCell
@end

@interface OutlookSettingsController : NSViewController<NSTableViewDataSource>
@property (assign) id<OutlookSettingsDelegate> delegate;
@property (assign) IBOutlet NSTextField *statusLabel;
@property (assign) IBOutlet NSButton *signInButton;
@property (assign) IBOutlet NSButton *signOutButton;
@property (assign) IBOutlet NSTableView *categoriesTable;
@property (assign) IBOutlet NSSegmentedCell *categoriesAddRemoveButton;
@end

NS_ASSUME_NONNULL_END
