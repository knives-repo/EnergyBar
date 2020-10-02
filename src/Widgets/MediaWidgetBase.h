//
//  MediaWidgetBase.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/2/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomWidget.h"

@interface MediaWidgetBase : CustomWidget

@property (retain) NSString* currentTitle;

- (void) nowPlayingNotification:(NSNotification*) notification;
- (void) playPause;

@end
