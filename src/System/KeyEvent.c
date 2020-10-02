/**
 * @file KeyEvent.c
 *
 * @copyright 2018-2019 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#include "KeyEvent.h"
#include <IOKit/hidsystem/IOHIDLib.h>
#include <CoreGraphics/CoreGraphics.h>
#include <pthread.h>

static pthread_once_t hid_conn_once = PTHREAD_ONCE_INIT;
static io_connect_t hid_conn = 0;

static void hid_conn_initonce(void)
{
    mach_port_t master_port;
    io_service_t serv = 0;
    kern_return_t ret;

    ret = IOMasterPort(bootstrap_port, &master_port);
    if (KERN_SUCCESS != ret)
        goto exit;

    serv = IOServiceGetMatchingService(master_port,
        IOServiceMatching(kIOHIDSystemClass)/* ref consumed by IOServiceGetMatchingService */);
    if (0 == serv)
        goto exit;

    ret = IOServiceOpen(serv, mach_task_self(), kIOHIDParamConnectType, &hid_conn);
    if (KERN_SUCCESS != ret)
        goto exit;

exit:
    if (0 != serv)
        IOObjectRelease(serv);
}

void PostKeyPress(uint16_t keyCode, uint32_t flags)
{
    CGEventRef eventDown;
    eventDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)keyCode, true);
    CGEventSetFlags(eventDown, flags);
    CGEventPost(kCGSessionEventTap, eventDown);
    CFRelease(eventDown);

    CGEventRef eventUp;
    eventUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)keyCode, false);
    CGEventSetFlags(eventUp, flags);
    CGEventPost(kCGSessionEventTap, eventUp);
    CFRelease(eventUp);

    /*NXEventData event = { 0 };
    IOGPoint point = { 0 };
    kern_return_t ret;

    pthread_once(&hid_conn_once, hid_conn_initonce);
    if (0 == hid_conn)
        return;

    event.key.repeat = 0;
    event.key.keyCode = keyCode;
    event.key.charSet = NX_ASCIISET;
    event.key.charCode = 0;
    event.key.origCharSet = event.key.charSet;
    event.key.origCharCode = event.key.charCode;

    ret = IOHIDPostEvent(hid_conn, NX_KEYDOWN, point, &event, kNXEventDataVersion, flags, 0);
    if (KERN_SUCCESS != ret)
        return;

    ret = IOHIDPostEvent(hid_conn, NX_KEYUP, point, &event, kNXEventDataVersion, flags, 0);
    if (KERN_SUCCESS != ret)
        return;
    */
}

void PostAuxKeyPress(uint16_t auxKeyCode)
{
    NXEventData event = { 0 };
    IOGPoint point = { 0 };
    kern_return_t ret;

    pthread_once(&hid_conn_once, hid_conn_initonce);
    if (0 == hid_conn)
        return;

    event.compound.subType = NX_SUBTYPE_AUX_CONTROL_BUTTONS;
    event.compound.misc.L[0] = (NX_KEYDOWN << 8) | (auxKeyCode << 16);
    ret = IOHIDPostEvent(hid_conn, NX_SYSDEFINED, point, &event, kNXEventDataVersion, 0, 0);
    if (KERN_SUCCESS != ret)
        return;

    event.compound.subType = NX_SUBTYPE_AUX_CONTROL_BUTTONS;
    event.compound.misc.L[0] = (NX_KEYUP << 8) | (auxKeyCode << 16);
    ret = IOHIDPostEvent(hid_conn, NX_SYSDEFINED, point, &event, kNXEventDataVersion, 0, 0);
    if (KERN_SUCCESS != ret)
        return;
}
