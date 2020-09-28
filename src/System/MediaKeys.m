//
//  MediaKeys.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/28/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "MediaKeys.h"

void HIDPostAuxKeyPress(uint32_t key) {
    HIDPostAuxKey(key, true);
    HIDPostAuxKey(key, false);
}

//
// from http://www.hari.xyz/2019/06/how-to-emulate-special-apple-keys-media.html
//

void HIDPostAuxKey(uint32_t key, bool down)
{
    @autoreleasepool {
        
        NSEvent* ev = [NSEvent otherEventWithType:NSEventTypeSystemDefined
                                         location:NSZeroPoint
                                    modifierFlags:(down ? 0xa00 : 0xb00)
                                        timestamp:0
                                     windowNumber:0
                                          context:nil
                                          subtype:8
                                            data1:(key << 16)| ((down ? 0xa : 0xb) << 8)
                                            data2:-1
                       ];
        CGEventPost(kCGHIDEventTap, [ev CGEvent]);
    }
}
