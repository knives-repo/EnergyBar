//
//  MediaKeys.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/28/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <IOKit/hidsystem/ev_keymap.h>

void HIDPostAuxKeyPress(uint32_t key);
void HIDPostAuxKey(uint32_t key, bool down);
