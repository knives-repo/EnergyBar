/**
 * @file ExpandedControlWidget.m
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

#import "ExpandedControlWidget.h"
#import "Appearance.h"
#import "AudioControl.h"
#import "Brightness.h"
#import "CBBlueLightClient.h"
#import "KeyEvent.h"
#import "NSTouchBar+SystemModal.h"
#import "NowPlaying.h"
#import "TouchBarController.h"
#import "BezelWindow.h"
#import "ControlWidgetLevelView.h"
#import "ControlWidgetView.h"

#define MaxPanDistance                  50.0
#define BrightnessAdjustIncrement			 (1.0/16.0)
#define VolumeAdjustIncrement					 (1.0/16.0)

@implementation ExpandedControlWidget
{
  NSInteger _pressKind;
  CGFloat _xmin, _xmax;
}

- (void)commonInit
{
  NSSegmentedControl *control = [NSSegmentedControl
                                 segmentedControlWithImages:[NSArray arrayWithObjects:
                                                             [NSImage imageNamed:@"BrightnessDown"],
                                                             [NSImage imageNamed:@"BrightnessUp"],
                                                             [NSImage imageNamed:NSImageNameTouchBarAudioOutputVolumeLowTemplate],
                                                             [NSImage imageNamed:NSImageNameTouchBarAudioOutputVolumeHighTemplate],
                                                             [self volumeMuteImage],
                                                             nil]
                                 trackingMode:NSSegmentSwitchTrackingMomentary
                                 target:self
                                 action:@selector(click:)];
  control.translatesAutoresizingMaskIntoConstraints = NO;
  control.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  control.tag = 'ctrl';
  
  ControlWidgetLevelView *level = [[[ControlWidgetLevelView alloc]
                                            initWithFrame:NSMakeRect(0, 0, MaxPanDistance, 20)] autorelease];
  level.wantsLayer = YES;
  level.layer.cornerRadius = 4.0;
  level.layer.borderWidth = 1.0;
  level.layer.borderColor = [[NSColor systemGrayColor] CGColor];
  level.translatesAutoresizingMaskIntoConstraints = NO;
  level.autoresizingMask = NSViewNotSizable;
  level.value = 0.5;
  level.inset = 4;
  level.tag = 'levl';
  level.hidden = YES;
  
  NSView *view = [[[ControlWidgetLevelView alloc] initWithFrame:NSZeroRect] autorelease];
  [view addSubview:control];
  [view addSubview:level];
  
  self.customizationLabel = @"Expanded Control";
  self.view = view;
  
  [AudioControl sharedInstanceOutput];
  
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter]
   removeObserver:self];
  
  [super dealloc];
}

- (void)viewWillAppear
{
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(audioControlNotification:)
   name:AudioControlNotification
   object:nil];
}

- (void)viewDidDisappear
{
  [[NSNotificationCenter defaultCenter]
   removeObserver:self];
}

- (NSImage *)volumeMuteImage
{
  BOOL mute = [AudioControl sharedInstanceOutput].mute;
  return [NSImage imageNamed:mute ? @"VolumeMuteOn" : @"VolumeMuteOff"];
}

- (void)audioControlNotification:(NSNotification *)notification
{
  NSSegmentedControl *control = [self.view viewWithTag:'ctrl'];
  [control setImage:[self volumeMuteImage] forSegment:4];
  
}

- (void)adjustBrightnessBy:(double)delta {
  double brgt = GetDisplayBrightness(0);
  brgt = MAX(0, MIN(1, brgt + delta));
  SetDisplayBrightness(0, brgt);
  [BezelWindow showWithType:kBrightness andValue:brgt];
}

- (void)adjustVolumeBy:(double)delta {
  double vol = [AudioControl sharedInstanceOutput].volume;
  vol = MAX(0, MIN(1,vol + delta));
  [AudioControl sharedInstanceOutput].volume = vol;
  [AudioControl sharedInstanceOutput].mute = (vol == 0);
  [BezelWindow showWithType:kAudioOutputVolume andValue:vol];
}

- (void)mute {
  
  BOOL mute = ![AudioControl sharedInstanceOutput].mute;
  [AudioControl sharedInstanceOutput].mute = mute;
  double vol = mute ? 0 : [AudioControl sharedInstanceOutput].volume;
  [BezelWindow showWithType:(mute ? kAudioOutputMute : kAudioOutputVolume) andValue:vol];
  
}

- (void)click:(id)sender
{
  NSSegmentedControl *control = sender;
  switch (control.selectedSegment)
  {
    case 0:
      // brightness down
      [self adjustBrightnessBy:-BrightnessAdjustIncrement];
      break;
    case 1:
      // brightness up
      [self adjustBrightnessBy:+BrightnessAdjustIncrement];
      break;
      break;
    case 2:
      // volume down
      [self adjustVolumeBy:-VolumeAdjustIncrement];
      break;
    case 3:
      // volume up
      [self adjustVolumeBy:+VolumeAdjustIncrement];
      break;
    case 4:
      [self mute];
      break;
  }
}

- (NSInteger)segmentForX:(CGFloat)x
{
  /* HACK:
   * There does not appear to be a direct way to determine the segment from a point.
   *
   * One would think that the -[NSSegmentedControl widthForSegment:] method on the
   * first segment (which happens to be the Play/Pause button) would do the trick.
   * Unfortunately this method returns 0 for automatically sized segments. Arrrrr!
   *
   * So I am adapting here some code that I wrote a long time for "DarwinKit"...
   */
  NSSegmentedControl *control = [self.view viewWithTag:'ctrl'];
  NSRect rect = control.bounds;
  CGFloat widths[16] = { 0 }, totalWidth = 0;
  NSInteger count = control.segmentCount, zeroWidthCells = 0;
  for (NSInteger i = 0; count > i; i++)
  {
    widths[i] = [control widthForSegment:i];
    if (0 == widths[i])
      zeroWidthCells++;
    else
      totalWidth += widths[i];
  }
  if (0 < zeroWidthCells)
  {
    totalWidth = rect.size.width - totalWidth;
    for (NSInteger i = 0; count > i; i++)
    if (0 == widths[i])
      widths[i] = totalWidth / zeroWidthCells;
  }
  else
  {
    if (2 <= count)
    {
      CGFloat remWidth = rect.size.width - totalWidth;
      widths[0] += remWidth / 2;
      widths[count - 1] += remWidth / 2;
    }
    else if (1 <= count)
    {
      CGFloat remWidth = rect.size.width - totalWidth;
      widths[0] += remWidth;
    }
  }
  
  /* now that we have the widths go ahead and figure out which segment has X */
  totalWidth = 0;
  for (NSInteger i = 0; count > i; i++)
  {
    if (totalWidth <= x && x < totalWidth + widths[i])
      return i;
    
    totalWidth += widths[i];
  }
  
  return -1;
}
@end
