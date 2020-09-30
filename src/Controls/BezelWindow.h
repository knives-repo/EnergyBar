//
//  BezelWindow.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/25/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

//
// From https://github.com/BlueHuskyStudios/BHBezelNotification
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    kAudioOutputVolume,
    kAudioOutputMute,
    kAudioInputOn,
    kAudioInputMute,
    kBrightness,
    kBacklight
} BezelType;

@interface BezelWindow : NSWindow

+ (BOOL) isDarkMode;

+ (void) showLevelFor:(BezelType) type withValue:(float) value;
+ (void) showWithMessage:(NSString*) message;
+ (void) showWithView:(NSView*) view;

+ (void) hide;

@property (assign) BezelType type;
@property (assign) float value;

@end

NS_ASSUME_NONNULL_END
