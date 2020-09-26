//
//  BezelWindow.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/25/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "BezelWindow.h"

#define WIDTH 200
#define HEIGHT 200
#define BOTTOM_MARGIN 140
#define CORNER_RADIUS 18
#define INDICATOR_MARGIN 20
#define INDICATOR_HEIGHT 8
#define INDICATOR_CELLS 16
#define FADE_DELAY 2

@implementation BezelWindow

@synthesize type;
@synthesize value;

+ (void) showWithType:(BezelType) type andValue:(float) value {
    
    static BezelWindow* instance = nil;
    static NSTimer* timer = nil;
    
    // immediatly close previous one
    if (instance != nil) {
        [timer invalidate];
        [instance close];
        instance = nil;
        timer = nil;
    }
    
    // now show new one
    instance = [[BezelWindow alloc] initWithType:type andValue:value];
    [instance makeKeyAndOrderFront:nil];
    
    // auto close
    timer = [NSTimer scheduledTimerWithTimeInterval:FADE_DELAY repeats:NO block:^(NSTimer * _Nonnull timer) {
        [instance fadeOut];
        instance = nil;
        timer = NULL;
    }];
    
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

- (id) initWithType:(BezelType) type andValue:(float) value {
    
    NSRect screenRect = [[NSScreen mainScreen] frame];
    NSRect contentRect = NSMakeRect((screenRect.size.width-WIDTH)/2, BOTTOM_MARGIN, WIDTH, HEIGHT);
    
    self = [super initWithContentRect:contentRect
                            styleMask:NSWindowStyleMaskBorderless
                              backing:NSBackingStoreBuffered
                                defer:FALSE];
    
    [self setContentView:[self makeVisualEffectsBackingView]];
    
    [self setMinSize:contentRect.size];
    [self setMaxSize:contentRect.size];
    
    [self setReleasedWhenClosed:YES];
    [self setLevel:CGShieldingWindowLevel()];
    [self setIgnoresMouseEvents:YES];
    [self setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
    [self setOpaque:NO];
    [self setBackgroundColor:[NSColor clearColor]];
    
    [self setType:type];
    [self setValue:value];
    [self addComponents];
    
    return self;
    
}

- (NSVisualEffectView*) makeVisualEffectsBackingView {
    
    NSVisualEffectView* view = [[NSVisualEffectView alloc] init];
    [view setWantsLayer:YES];
    [view setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
    [view setMaterial:NSVisualEffectMaterialDark];
    [view setState:NSVisualEffectStateActive];
    [view setMaskImage:[self roundedRectMaskOfSize:NSMakeSize(WIDTH, HEIGHT) andCornerRadius:CORNER_RADIUS]];
    return view;
}

- (NSImage*) roundedRectMaskOfSize:(NSSize) size andCornerRadius:(float) cornerRadius {
    
    NSImage* mask = [[NSImage alloc] initWithSize:size];
    [mask lockFocus];
    
    NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, size.width, size.height)
                                                         xRadius:cornerRadius
                                                         yRadius:cornerRadius];
    [[NSColor blackColor] set];
    [path fill];
    
    [mask unlockFocus];
    [mask setCapInsets:NSEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius)];
    [mask setResizingMode:NSImageResizingModeStretch];
    
    return mask;
    
}

- (void) addComponents {
    
    [self.contentView setWantsLayer:YES];
    
    NSImageView* iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(WIDTH/4, HEIGHT/4, WIDTH/2, HEIGHT/2)];
    [iconView setImage:[NSImage imageNamed:[self imageName]]];
    [iconView setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.contentView addSubview:iconView];
    
    if (value >= 0) {
        NSLevelIndicator* levelIndicator = [[NSLevelIndicator alloc] initWithFrame:NSMakeRect(INDICATOR_MARGIN, INDICATOR_MARGIN, WIDTH-2*INDICATOR_MARGIN, INDICATOR_HEIGHT)];
        [levelIndicator setMaxValue:INDICATOR_CELLS];
        [levelIndicator setIntValue:INDICATOR_CELLS*self.value];
        [levelIndicator setFillColor:[NSColor colorWithWhite:1.0 alpha:0.9]];
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
