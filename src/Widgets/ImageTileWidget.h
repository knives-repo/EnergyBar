//
//  ImageTileWidget.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/27/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomWidget.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImageTileWidget : CustomWidget

- (id) initWithIdentifier:(NSString*) identifier customizationLabel:(NSString*) label title:(NSString*) title;
- (id) initWithIdentifier:(NSString*) identifier customizationLabel:(NSString*) label title:(NSString*) title icon:(NSImage*) icon;
- (id) initWithIdentifier:(NSString*) identifier customizationLabel:(NSString*) label title:(NSString*) title icon:(NSImage*) icon subtitle:(NSString*) subtitle;

-(void)update;

@end

NS_ASSUME_NONNULL_END
