//
//  VolumeWidget.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/30/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CustomWidget.h"

NS_ASSUME_NONNULL_BEGIN

@interface VolumeWidget : CustomMultiWidget
@property (nonatomic,assign) BOOL showsSmallWidget;
@end

NS_ASSUME_NONNULL_END
