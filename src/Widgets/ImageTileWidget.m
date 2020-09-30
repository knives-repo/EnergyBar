//
//  ImageTileWidget.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/27/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import "ImageTileWidget.h"
#import "ImageTitleView.h"

@interface ImageTileWidget()
@property (retain) NSString* title;
@property (retain) NSString* subtitle;
@property (retain) NSImage* icon;
@end

@implementation ImageTileWidget

- (id) initWithIdentifier:(NSString*) identifier customizationLabel:(NSString*) label title:(NSString*) title {
    self = [super initWithIdentifier:identifier];
    self.customizationLabel = label;
    self.title = title;
    [self update];
    return self;
}

- (id) initWithIdentifier:(NSString*) identifier customizationLabel:(NSString*) label title:(NSString*) title icon:(NSImage*) icon {
    self = [super initWithIdentifier:identifier];
    self.customizationLabel = label;
    self.title = title;
    self.icon = icon;
    [self update];
    return self;
}

- (id) initWithIdentifier:(NSString*) identifier customizationLabel:(NSString*) label title:(NSString*) title icon:(NSImage*) icon subtitle:(NSString*) subtitle {
    self = [super initWithIdentifier:identifier];
    self.customizationLabel = label;
    self.title = title;
    self.subtitle = subtitle;
    self.icon = icon;
    [self update];
    return self;
}

- (void)commonInit
{
    // formatting
    ImageTitleView *view = [[[ImageTitleView alloc] initWithFrame:NSZeroRect] autorelease];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 8.0;
    view.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    view.imageSize = NSMakeSize(20, 20);
    view.titleFont = [NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeRegular-1]];
    view.titleLineBreakMode = NSLineBreakByTruncatingTail;
    view.subtitleFont = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]];
    view.subtitleLineBreakMode = NSLineBreakByTruncatingTail;
    self.view = view;

}

-(void)update {
    
    // format
    ImageTitleViewLayoutOptions layoutOptions = 0;
    if (nil != self.icon)
        layoutOptions = layoutOptions | ImageTitleViewLayoutOptionImage;
    if (nil != self.title)
        layoutOptions = layoutOptions | ImageTitleViewLayoutOptionTitle;
    if (nil != self.subtitle)
        layoutOptions = layoutOptions | ImageTitleViewLayoutOptionSubtitle;

    // update
    ImageTitleView *view = self.view;
    view.image = self.icon;
    view.title = self.title;
    view.subtitle = self.subtitle;
    view.layoutOptions = layoutOptions;

}

@end
