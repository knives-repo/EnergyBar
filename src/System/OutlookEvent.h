//
//  OutlookEvent.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/27/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    Unknown,
    Free,
    Tentative,
    Busy,
    OutOfOffice,
} ShowAs;

@interface OutlookEvent : NSObject

@property (retain) NSString* title;
@property (retain) NSDate* startTime;
@property (assign) ShowAs showAs;
@property (retain) NSString* webLink;
@property (retain) NSString* joinUrl;
@property (readonly) BOOL isCurrent;

+ (NSString*) dateDiffDescriptionBetween:(NSDate*) reference and:(NSDate*) date;

+ (NSArray*) listFromJson:(NSArray*) jsonArray;

+ (OutlookEvent*) findSoonestEvent:(NSArray*) events busyOnly:(BOOL) busyOnly;

- (id) initWithJson:(NSDictionary*) jsonEvent;
- (NSString*) startTimeDesc;

@end

NS_ASSUME_NONNULL_END
