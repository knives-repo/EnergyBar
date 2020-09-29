//
//  BezelWindow.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/25/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "BezelWindow.h"
#import "LevelIndicator.h"
#import "NSColor+Hex.h"

#define BOTTOM_MARGIN 140
#define CORNER_RADIUS 18
#define FADE_DELAY 2

#define HUD_WIDTH 200
#define HUD_HEIGHT 200
#define HUD_ICON_MARGIN 40
#define HUD_INDICATOR_MARGIN 20
#define HUD_INDICATOR_HEIGHT 8

#define ALERT_WIDTH 600
#define ALERT_HEIGHT 60
#define ALERT_MARGIN 16

static BezelWindow* instance = nil;
static NSTimer* timer = nil;

@implementation BezelWindow

@synthesize type;
@synthesize value;

+ (BOOL) isDarkMode {
    if (@available(macOS 10.14, *)) {
        NSView* view = [[NSView alloc] init];
        NSAppearance* appearance = view.effectiveAppearance;
        NSAppearanceName basicAppearance = [appearance bestMatchFromAppearancesWithNames:@[
            NSAppearanceNameAqua,
            NSAppearanceNameDarkAqua
        ]];
        return [basicAppearance isEqualToString:NSAppearanceNameDarkAqua];
    } else {
        return NO;
    }
}

+ (void) showWithType:(BezelType) type andValue:(float) value {
    [BezelWindow show:[[BezelWindow alloc] initWithType:type andValue:value]];
}

+ (void) showWithMessage:(NSString*) message {
    [BezelWindow show:[[BezelWindow alloc] initWithMessage:message]];
}

+ (void) show:(BezelWindow*) window {
    
    // immediatly close previous one
    [BezelWindow hide];
    
    // now show new one
    instance = window;
    [instance makeKeyAndOrderFront:nil];
    
    // auto close
    timer = [NSTimer scheduledTimerWithTimeInterval:FADE_DELAY repeats:NO block:^(NSTimer * _Nonnull timer) {
        [instance fadeOut];
        instance = nil;
        timer = NULL;
    }];

}

+ (void) hide {
    if (instance != nil) {
        [timer invalidate];
        [instance close];
        instance = nil;
        timer = nil;
    }
}

- (void)fadeOut {
    
    float alpha = 1.0;
    [self setAlphaValue:alpha];
    [self makeKeyAndOrderFront:self];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.35f];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        [self close];
    }];
    [[self animator] setAlphaValue:0.f];
    [NSAnimationContext endGrouping];
}

- (id) initWithFrame:(NSRect) frame forDarkMode:(BOOL) darkMode {
    
    self = [super initWithContentRect:frame
                            styleMask:NSWindowStyleMaskBorderless
                              backing:NSBackingStoreBuffered
                                defer:FALSE];
    [self setContentView:[self makeVisualEffectsBackingView:frame forDarkMode:darkMode]];

    [self setMinSize:frame.size];
    [self setMaxSize:frame.size];

    [self setAppearance:
     [NSAppearance appearanceNamed:(darkMode ? NSAppearanceNameVibrantDark : NSAppearanceNameVibrantLight)]
     ];

    [self setReleasedWhenClosed:YES];
    [self setLevel:CGShieldingWindowLevel()];
    [self setIgnoresMouseEvents:YES];
    [self setOpaque:NO];
    [self setBackgroundColor:[NSColor clearColor]];
    
    return self;
    
}

- (id) initWithType:(BezelType) type andValue:(float) value {
    
    NSRect screenRect = [[NSScreen mainScreen] frame];
    NSRect contentRect = NSMakeRect((screenRect.size.width-HUD_WIDTH)/2, BOTTOM_MARGIN, HUD_WIDTH, HUD_HEIGHT);

    self = [self initWithFrame:contentRect forDarkMode:[BezelWindow isDarkMode]];
    
    [self setType:type];
    [self setValue:value];
    [self addComponents:contentRect.size];
    
    return self;
    
}

- (id) initWithMessage:(NSString*) message {
    
    NSRect screenRect = [[NSScreen mainScreen] frame];
    NSRect contentRect = NSMakeRect((screenRect.size.width-ALERT_WIDTH)/2, BOTTOM_MARGIN, ALERT_WIDTH, ALERT_HEIGHT);

    self = [self initWithFrame:contentRect forDarkMode:YES];
    
    NSTextField* text = [[NSTextField alloc] initWithFrame:NSMakeRect(ALERT_MARGIN, -12, ALERT_WIDTH-2*ALERT_MARGIN, ALERT_HEIGHT)];
    [text setBackgroundColor:[NSColor clearColor]];
    [text setFont:[NSFont fontWithName:@"Avenir Next" size:20]];
    [text setAlignment:NSTextAlignmentCenter];
    [text setTextColor:[NSColor whiteColor]];
    [text setStringValue:message];
    [text setEditable:NO];
    [text setBezeled:NO];

    [self.contentView addSubview:text];
    
    return self;

}

- (NSVisualEffectView*) makeVisualEffectsBackingView:(NSRect) rect forDarkMode:(BOOL) darkMode {
    
    NSVisualEffectView* view = [[NSVisualEffectView alloc] init];
    [view setWantsLayer:YES];
    [view setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
    [view setMaterial:(darkMode ? NSVisualEffectMaterialDark : NSVisualEffectMaterialLight)];
    [view setState:NSVisualEffectStateActive];
    [view setMaskImage:[self roundedRectMaskOfSize:rect.size andCornerRadius:CORNER_RADIUS forDarkMode:darkMode]];
    return view;
}

- (NSImage*) roundedRectMaskOfSize:(NSSize) size andCornerRadius:(float) cornerRadius forDarkMode:(BOOL) darkMode {
    
    NSImage* mask = [[NSImage alloc] initWithSize:size];
    [mask lockFocus];
    
    NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, size.width, size.height)
                                                         xRadius:cornerRadius
                                                         yRadius:cornerRadius];
    [[NSColor colorWithCalibratedWhite:(darkMode ? 0 : 1) alpha:1.0] set];
    [path fill];
    
    [mask unlockFocus];
    [mask setCapInsets:NSEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius)];
    [mask setResizingMode:NSImageResizingModeStretch];
    
    return mask;
    
}

- (void) addComponents:(NSSize) size {
    
    [self.contentView setWantsLayer:YES];
    //[self.contentView.layer setBackgroundColor:[[NSColor colorWithCalibratedWhite:0 alpha:0.15] CGColor]];
    
    // icon
    NSImageView* iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(
        HUD_ICON_MARGIN, HUD_ICON_MARGIN + (value >= 0 ? HUD_INDICATOR_MARGIN : 0) / 2,
        size.width - 2 * HUD_ICON_MARGIN, size.height - 2 * HUD_ICON_MARGIN
    )];
    [iconView setImage:[NSImage imageNamed:[self imageName]]];
    if (@available(macOS 10.14, *)) {
        if ([BezelWindow isDarkMode]) {
            [iconView setContentTintColor:[NSColor colorFromHex:0x888888]];
        }
    }
    [iconView setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.contentView addSubview:iconView];
    
    // value
    if (value >= 0) {
        LevelIndicator* levelIndicator = [[LevelIndicator alloc] initWithFrame:NSMakeRect(
            HUD_INDICATOR_MARGIN, HUD_INDICATOR_MARGIN,
            size.width-2*HUD_INDICATOR_MARGIN, HUD_INDICATOR_HEIGHT
        )];
        [levelIndicator setValue:self.value];
        [self.contentView addSubview:levelIndicator];
    }
    
}

- (NSImageName) imageName {
    switch (self.type) {
        case kAudioOutputVolume:
            return NSImageNameTouchBarAudioOutputVolumeHighTemplate;
        case kAudioOutputMute:
            return NSImageNameTouchBarAudioOutputMuteTemplate;
        case kAudioInputOn:
            return NSImageNameTouchBarAudioInputTemplate;
        case kAudioInputMute:
            return NSImageNameTouchBarAudioInputMuteTemplate;
        case kBrightness:
            return @"BrightnessIndicator";
        case kBacklight:
            return @"KeyboardBrightnessUp";
        default:
            return NULL;
    }
}

@end
