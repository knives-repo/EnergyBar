//
//  BezelWindow.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/25/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "BezelWindow.h"
#import "LevelIndicator.h"

#define WIDTH 200
#define HEIGHT 200
#define BOTTOM_MARGIN 140
#define CORNER_RADIUS 18
#define ICON_MARGIN 40
#define INDICATOR_MARGIN 20
#define INDICATOR_HEIGHT 8
#define FADE_DELAY 2

@implementation BezelWindow

@synthesize type;
@synthesize value;

+ (BOOL) isDarkMode {
    return FALSE;
}

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
    [self setAppearance:
     [NSAppearance appearanceNamed:([BezelWindow isDarkMode] ? NSAppearanceNameVibrantDark : NSAppearanceNameVibrantLight)]
     ];
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
    [view setMaterial:([BezelWindow isDarkMode] ? NSVisualEffectMaterialDark : NSVisualEffectMaterialLight)];
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
    [[NSColor colorWithCalibratedWhite:([BezelWindow isDarkMode] ? 0 : 1) alpha:1.0] set];
    [path fill];
    
    [mask unlockFocus];
    [mask setCapInsets:NSEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius)];
    [mask setResizingMode:NSImageResizingModeStretch];
    
    return mask;
    
}

- (void) addComponents {
    
    [self.contentView setWantsLayer:YES];
    //[self.contentView.layer setBackgroundColor:[[NSColor colorWithCalibratedWhite:0 alpha:0.15] CGColor]];
    
    NSImageView* iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(
        ICON_MARGIN, ICON_MARGIN + (value >= 0 ? INDICATOR_MARGIN : 0) / 2,
        WIDTH - 2 * ICON_MARGIN, HEIGHT - 2 * ICON_MARGIN
    )];
    [iconView setImage:[NSImage imageNamed:[self imageName]]];
    //[iconView setAlphaValue:[[self imageName] hasPrefix:@"NS"] ? 1.0 : 0.6];
    [iconView setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.contentView addSubview:iconView];
    
    
    
    if (value >= 0) {
        LevelIndicator* levelIndicator = [[LevelIndicator alloc] initWithFrame:NSMakeRect(INDICATOR_MARGIN, INDICATOR_MARGIN, WIDTH-2*INDICATOR_MARGIN, INDICATOR_HEIGHT)];
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
