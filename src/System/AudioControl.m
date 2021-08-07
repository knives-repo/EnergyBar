/**
 * @file AudioControl.m
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

#include "AudioControl.h"
#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioServices.h>
#include "Log.h"

@interface AudioControl ()
- (void)systemObjectPropertyDidChange;
- (void)audioDevicePropertyDidChange;
@end

static OSStatus SystemObjectPropertyListener(
    AudioObjectID device,
    UInt32 count, const AudioObjectPropertyAddress* addresses,
    void *data)
{
    [(id)data
        performSelectorOnMainThread:@selector(systemObjectPropertyDidChange)
        withObject:nil
        waitUntilDone:NO];
    return kAudioHardwareNoError;
}

static OSStatus AudioDeviceMuteListener(
    AudioObjectID device,
    UInt32 count, const AudioObjectPropertyAddress* addresses,
    void *data)
{
    [(id)data
        performSelectorOnMainThread:@selector(audioDevicePropertyDidChange)
        withObject:@"mute"
        waitUntilDone:NO];
    return kAudioHardwareNoError;
}

static OSStatus AudioDeviceVolumeListener(
    AudioObjectID device,
    UInt32 count, const AudioObjectPropertyAddress* addresses,
    void *data)
{
    [(id)data
        performSelectorOnMainThread:@selector(audioDevicePropertyDidChange)
        withObject:@"volume"
        waitUntilDone:NO];
    return kAudioHardwareNoError;
}

@implementation AudioControl
{
    AudioObjectPropertySelector _selector;
    AudioObjectPropertyScope _scope;
    AudioDeviceID _audiodev;
}

+ (AudioControl *)sharedInstanceOutput
{
    static AudioControl *instance = 0;
    if (0 == instance)
        instance = [[AudioControl alloc] init:TRUE];
    return instance;
}

+ (AudioControl *)sharedInstanceInput
{
    static AudioControl *instance = 0;
    if (0 == instance)
        instance = [[AudioControl alloc] init:FALSE];
    return instance;
}

- (id)init:(BOOL) output
{
    self = [super init];
    if (nil == self)
        return nil;

    _audiodev = kAudioObjectUnknown;
    _selector = output ? kAudioHardwarePropertyDefaultOutputDevice : kAudioHardwarePropertyDefaultInputDevice;
    _scope = output ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;

    [self registerSystemObjectListener:YES];
    [self getAudioDevice:YES];

    return self;
}

- (void)dealloc
{
    [self resetAudioDevice];
    [self registerSystemObjectListener:NO];

    [super dealloc];
}

- (double)volume
{
    AudioObjectPropertyAddress address =
    {
        .mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
        .mScope = _scope,
        .mElement = kAudioObjectPropertyElementMaster,
    };
    __block Float32 volume = NAN;
    OSStatus status;

    status = [self _retry:^OSStatus(AudioDeviceID audiodev)
    {
        UInt32 size = sizeof volume;
        return AudioObjectGetPropertyData(audiodev, &address, 0, 0, &size, &volume);
    }];
    if (kAudioHardwareNoError != status)
    {
        LOG("AudioObjectGetPropertyData = %d", status);
        return NAN;
    }

    return volume;
}

- (void)setVolume:(double)value
{
    AudioObjectPropertyAddress address =
    {
        .mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
        .mScope = _scope,
        .mElement = kAudioObjectPropertyElementMaster,
    };
    Float32 volume = value;
    OSStatus status;

    status = [self _retry:^OSStatus(AudioDeviceID audiodev)
    {
        return AudioObjectSetPropertyData(audiodev, &address, 0, 0, sizeof volume, &volume);
    }];
    if (kAudioHardwareNoError != status)
        LOG("AudioObjectSetPropertyData = %d", status);
}

- (BOOL)isMute
{
    AudioObjectPropertyAddress address =
    {
        .mSelector = kAudioDevicePropertyMute,
        .mScope = _scope,
        .mElement = kAudioObjectPropertyElementMaster,
    };
    __block UInt32 mute = 0;
    OSStatus status;

    status = [self _retry:^OSStatus(AudioDeviceID audiodev)
    {
        UInt32 size = sizeof mute;
        return AudioObjectGetPropertyData(audiodev, &address, 0, 0, &size, &mute);
    }];
    if (kAudioHardwareNoError != status)
    {
        LOG("AudioObjectGetPropertyData = %d", status);
        return FALSE;
    }

    return !!mute;
}

- (void)setMute:(BOOL)value
{
    AudioObjectPropertyAddress address =
    {
        .mSelector = kAudioDevicePropertyMute,
        .mScope = _scope,
        .mElement = kAudioObjectPropertyElementMaster,
    };
    UInt32 mute = !!value;
    OSStatus status;

    status = [self _retry:^OSStatus(AudioDeviceID audiodev)
    {
        return AudioObjectSetPropertyData(audiodev, &address, 0, 0, sizeof mute, &mute);
    }];
    if (kAudioHardwareNoError != status)
        LOG("AudioObjectSetPropertyData = %d", status);
}

- (OSStatus)_retry:(OSStatus (^)(AudioDeviceID audiodev))block
{
    OSStatus status = kAudioHardwareNoError;

    for (NSUInteger i = 0; 2 > i; i++)
    {
        status = block([self getAudioDevice:0 != i]);
        if (kAudioHardwareBadObjectError != status)
            break;
    }

    return status;
}

- (AudioDeviceID)getAudioDevice:(BOOL)init
{
    if (kAudioObjectUnknown == _audiodev || init)
    {
        AudioObjectPropertyAddress address =
        {
            .mSelector = _selector,
            .mScope = kAudioObjectPropertyScopeGlobal,
            .mElement = kAudioObjectPropertyElementMaster,
        };
        AudioDeviceID device = kAudioObjectUnknown;
        UInt32 size = sizeof device;
        OSStatus status;

        status = AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, 0, &size, &device);
        if (kAudioHardwareNoError != status)
            LOG("AudioObjectGetPropertyData = %d", status);
        else
        {
            _audiodev = device;

            AudioObjectPropertyAddress address =
            {
                .mSelector = kAudioDevicePropertyMute,
                .mScope = _scope,
                .mElement = kAudioObjectPropertyElementMaster,
            };

            status = AudioObjectAddPropertyListener(
                device, &address, AudioDeviceMuteListener, self);
            if (kAudioHardwareNoError != status)
                LOG("AudioObjectAddPropertyListener = %d", status);

            address.mSelector = kAudioDevicePropertyVolumeScalar;

            status = AudioObjectAddPropertyListener(
                device, &address, AudioDeviceVolumeListener, self);
            if (kAudioHardwareNoError != status)
                LOG("AudioObjectAddPropertyListener = %d", status);

        }
    }

    return _audiodev;
}

- (void)resetAudioDevice
{
    if (kAudioObjectUnknown != _audiodev)
    {
        AudioObjectPropertyAddress address =
        {
            .mSelector = kAudioDevicePropertyMute,
            .mScope = _scope,
            .mElement = kAudioObjectPropertyElementMaster,
        };
        OSStatus status;

        status = AudioObjectRemovePropertyListener(
            _audiodev, &address, AudioDeviceMuteListener, self);
        if (kAudioHardwareNoError != status)
            LOG("AudioObjectRemovePropertyListener = %d", status);

        address.mSelector = kAudioDevicePropertyVolumeScalar;
        
        status = AudioObjectRemovePropertyListener(
            _audiodev, &address, AudioDeviceVolumeListener, self);
        if (kAudioHardwareNoError != status)
            LOG("AudioObjectRemovePropertyListener = %d", status);
    }
}

- (void)registerSystemObjectListener:(BOOL)add
{
    AudioObjectPropertyAddress address =
    {
        .mSelector = _selector,
        .mScope = kAudioObjectPropertyScopeGlobal,
        .mElement = kAudioObjectPropertyElementMaster,
    };
    OSStatus status;

    if (add)
    {
        status = AudioObjectAddPropertyListener(
            kAudioObjectSystemObject, &address, SystemObjectPropertyListener, self);
        if (kAudioHardwareNoError != status)
            LOG("AudioObjectAddPropertyListener = %d", status);
    }
    else
    {
        status = AudioObjectRemovePropertyListener(
            kAudioObjectSystemObject, &address, SystemObjectPropertyListener, self);
        if (kAudioHardwareNoError != status)
            LOG("AudioObjectRemovePropertyListener = %d", status);
    }
}

- (void)systemObjectPropertyDidChange
{
    [self resetAudioDevice];
    [self getAudioDevice:YES];
}

- (void)audioDevicePropertyDidChange
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:AudioControlNotification
        object:self];
}
@end

NSString *AudioControlNotification = @"AudioControl";
