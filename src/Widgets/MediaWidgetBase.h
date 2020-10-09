//
//  MediaWidgetBase.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/2/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomWidget.h"

@interface MediaNotificationController : NSViewController
@property (assign) IBOutlet NSTextField *titleView;
@property (assign) IBOutlet NSImageView *iconView;
@property (assign) IBOutlet NSTextField *artistView;
@end

@interface MediaWidgetBase : CustomWidget

@property (retain) NSString* currentTitle;

- (void) viewWillAppear;

- (void) nowPlayingNotification:(NSNotification*) notification;
- (void) playPause;

- (BOOL) showLyrics;

@end
