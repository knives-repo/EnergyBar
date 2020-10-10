//
//  ButtonWidget.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/10/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CustomWidget.h"

NS_ASSUME_NONNULL_BEGIN

@interface ButtonWidget : CustomWidget

- (void) commonInit:(BOOL) gestureRecognizer;

- (void) setImage:(NSImage*) image;
- (void) setImageSize:(NSSize) size;
- (void) setBackgroundColor:(NSColor*) color;

@end

NS_ASSUME_NONNULL_END
