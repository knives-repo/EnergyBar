//
//  OutlookEvent.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/27/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    ShowAsUnknown,
    ShowAsFree,
    ShowAsTentative,
    ShowAsBusy,
    ShowAsOutOfOffice,
} ShowAs;

typedef enum {
    ImportanceLow,
    ImportanceNormal,
    ImportanceHigh,
} Importance;

@interface OutlookEvent : NSObject

@property (retain) NSString* uid;
@property (retain) NSString* title;
@property (assign) BOOL allDay;
@property (assign) BOOL cancelled;
@property (retain) NSDate* startTime;
@property (retain) NSDate* endTime;
@property (assign) ShowAs showAs;
@property (assign) Importance importance;
@property (retain) NSArray* categories;
@property (retain) NSString* organizerName;
@property (retain) NSString* organizerEmail;
@property (retain,nullable) NSString* onlineProvider;
@property (retain,nullable) NSString* webLink;
@property (retain,nullable) NSString* joinUrl;

@property (readonly) BOOL canBeJoined;
@property (readonly) BOOL isEnded;

+ (NSArray*) listFromJson:(NSArray*) jsonArray;

+ (OutlookEvent*) findSoonestEvent:(NSArray*) events busyOnly:(BOOL) busyOnly;

- (id) initWithJson:(NSDictionary*) jsonEvent;

- (NSTimeInterval) intervalWithNow;

- (NSString*) timingDesc;
- (NSString*) directJoinUrl;

- (BOOL) isZoom;
- (BOOL) isSkype;
- (BOOL) isTeams;
- (BOOL) isWebEx;
- (BOOL) isGoogleMeet;

- (NSString*) description;

@end

NS_ASSUME_NONNULL_END
