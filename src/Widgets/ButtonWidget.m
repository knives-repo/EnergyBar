//
//  ButtonWidget.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/10/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import "ButtonWidget.h"

@interface ButtonWidgetCell : NSButtonCell
@property (assign) NSSize imageSize;
@end

@implementation ButtonWidgetCell

- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView {
    
    // adjust size
    if (self.imageSize.width != 0 && self.imageSize.height != 0) {

        // calc rect
        float width = MAX(self.imageSize.width, controlView.frame.size.width);
        float height = MAX(self.imageSize.height, controlView.frame.size.height);
        float x = (controlView.frame.size.width - width) / 2;
        float y = (controlView.frame.size.height - height) / 2;
        frame = NSMakeRect(x, y, width, height);
        //NSLog(@"%@",CGRectCreateDictionaryRepresentation(frame));
        
    }

    // draw
    [super drawImage:image withFrame:frame inView:controlView];
}

@end

@interface ButtonWidgetView : NSButton
@end

@implementation ButtonWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(WIDGET_STANDARD_WIDTH, NSViewNoIntrinsicMetric);
}
@end

@interface ButtonWidget()
@property (retain) NSButton* buttonView;
@end

@implementation ButtonWidget

- (void)commonInit
{
    [self commonInit:NO];
}

- (void) commonInit:(BOOL) gestureRecognizer
{
    self.buttonView = [[[ButtonWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    [self.buttonView setCell:[[ButtonWidgetCell alloc] init]];
    [self.buttonView setBezelStyle:NSRoundedBezelStyle];
    [self.buttonView setButtonType:NSButtonTypeMomentaryPushIn];
    [self.buttonView setImagePosition:NSImageOnly];
    [self.buttonView setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.buttonView setWantsLayer:YES];
    [self.buttonView.layer setCornerRadius:6.0];
    
    self.view = self.buttonView;

    if (gestureRecognizer) {
        NSPressGestureRecognizer *shortPress = [[[NSPressGestureRecognizer alloc]
            initWithTarget:self action:@selector(shortPressAction:)] autorelease];
        shortPress.allowedTouchTypes = NSTouchTypeMaskDirect;
        shortPress.minimumPressDuration = 0;
        [self.view addGestureRecognizer:shortPress];
    } else {
        [self.view setTarget:self];
        [self.view setAction:@selector(tapAction:)];
    }

}

- (void) setImage:(NSImage*) image
{
    [self.buttonView setImage:image];
    [self.buttonView layout];
}

- (void) setImageSize:(NSSize) size
{
    ButtonWidgetCell* cell = self.buttonView.cell;
    [cell setImageSize:size];
    [self.buttonView layout];
}

- (void) setBackgroundColor:(NSColor*) color
{
    [self.buttonView setBezelColor:color];
    [self.buttonView layout];
}

- (void)tapAction:(id)sender
{
}

- (void)shortPressAction:(NSGestureRecognizer *)recognizer
{
    switch (recognizer.state)
    {
    case NSGestureRecognizerStateBegan:
        [self shortPressBegan:recognizer];
        break;
    case NSGestureRecognizerStateChanged:
        [self shortPressChanged:recognizer];
        break;
    case NSGestureRecognizerStateEnded:
    case NSGestureRecognizerStateCancelled:
        [self shortPressEnded:recognizer];
        break;
    default:
        return;
    }
}

- (void)shortPressBegan:(NSGestureRecognizer *)recognizer
{
}

- (void)shortPressChanged:(NSGestureRecognizer *)recognizer
{
}

- (void)shortPressEnded:(NSGestureRecognizer *)recognizer
{
}

@end
