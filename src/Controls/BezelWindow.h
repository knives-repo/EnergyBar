//
//  BezelWindow.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/25/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
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

+ (void) showWithType:(BezelType) type andValue:(float) value;

@property (assign) BezelType type;
@property (assign) float value;

@end

NS_ASSUME_NONNULL_END
