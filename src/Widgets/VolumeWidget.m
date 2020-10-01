//
//  VolumeWidget.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/30/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "VolumeWidget.h"
#import "VolumeControlsWidget.h"
#import "VolumeAllInOneWidget.h"

@implementation VolumeWidget

- (void)commonInit
{
    // dynamic sizing
    self.dynamicSizing = YES;

    // add widgets
    [self addWidget:[[VolumeControlsWidget alloc] initWithIdentifier:@"_volumeControls"]];
    [self addWidget:[[VolumeAllInOneWidget alloc] initWithIdentifier:@"_volumeAllInOne"]];

}

- (void)viewWillAppear {
    BOOL showsSmallWidget = [[NSUserDefaults standardUserDefaults] boolForKey:@"volumeShowsSmallWidget"];
    [self setShowsSmallWidget:showsSmallWidget];
}

- (void)setShowsSmallWidget:(BOOL)value
{
    [self setActiveIndex:value ? 1 : 0];
    [self.view invalidateIntrinsicContentSize];
}

@end
