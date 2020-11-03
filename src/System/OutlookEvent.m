//
//  OutlookEvent.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/27/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import "OutlookEvent.h"
#import "NSDate+Utils.h"
#import "NSDictionary+JSON.h"

// event is starting: should start to show join icon
#define EVENT_STARTING_DELTA_MINUTES 3

// event is in progress: still show up in the calendar
#define EVENT_IN_PROGRESS_FOR 15*60

// event is soon: display relative duration vs absolute time
#define EVENT_SOON_DELTA 1*60*60

// main online meetings providers
#define PROVIDER_TEAMS @"teamsForBusiness"
#define PROVIDER_SKYPE @"skypeForBusiness"

@implementation OutlookEvent

- (NSString*) description {
    return [NSString stringWithFormat:@"[EVENT] %@: %@ (%@)", self.startTime, self.title, [self.categories componentsJoinedByString:@"/"]];
}

- (id) init {
    self = [super init];
    self.showAs = ShowAsUnknown;
    self.importance = ImportanceNormal;
    return self;
}

- (id) initWithJson:(NSDictionary*) jsonEvent {
    
    // start with easy one
    self = [self init];
    self.uid = [jsonEvent getJsonValue:@"id"];
    self.title = [jsonEvent getJsonValue:@"subject"];
    self.webLink = [jsonEvent getJsonValue:@"webLink"];
    self.cancelled = [[jsonEvent getJsonValue:@"isCancelled"] boolValue];

    // organizer
    self.organizerName = [jsonEvent getJsonValue:@"organizer" sub1:@"emailAddress" sub2:@"name"];
    self.organizerEmail = [jsonEvent getJsonValue:@"organizer" sub1:@"emailAddress" sub2:@"address"];

    // show as
    self.showAs = ShowAsUnknown;
    NSString* jsonShowAs = [jsonEvent getJsonValue:@"showAs"];
    if ([jsonShowAs caseInsensitiveCompare:@"free"] == NSOrderedSame) {
        self.showAs = ShowAsFree;
    } else if ([jsonShowAs caseInsensitiveCompare:@"busy"] == NSOrderedSame) {
        self.showAs = ShowAsBusy;
    } else if ([jsonShowAs caseInsensitiveCompare:@"tentative"] == NSOrderedSame) {
        self.showAs = ShowAsTentative;
    } else if ([jsonShowAs caseInsensitiveCompare:@"oof"] == NSOrderedSame) {
        self.showAs = ShowAsOutOfOffice;
    } else if ([jsonShowAs caseInsensitiveCompare:@"workingelsewhere"] == NSOrderedSame) {
        self.showAs = ShowAsBusy;
    }
    
    // importance
    self.importance = ImportanceNormal;
    NSString* jsonImportance = [jsonEvent getJsonValue:@"importance"];
    if ([jsonImportance caseInsensitiveCompare:@"low"] == NSOrderedSame) {
        self.importance = ImportanceLow;
    } else if ([jsonImportance caseInsensitiveCompare:@"high"] == NSOrderedSame) {
        self.importance = ImportanceHigh;
    }
    
    // start date: 2020-09-28T01:00:00.0000000
    NSString* jsonStartDate = [jsonEvent getJsonValue:@"start" sub:@"dateTime"];
    NSString* jsonEndDate = [jsonEvent getJsonValue:@"end" sub:@"dateTime"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
    self.startTime = [dateFormatter dateFromString:jsonStartDate];
    self.endTime = [dateFormatter dateFromString:jsonEndDate];
    self.allDay = [[jsonEvent getJsonValue:@"isAllDay"] boolValue];
    
    // categories
    self.categories = [jsonEvent getJsonValue:@"categories"];
    if ([self.categories isKindOfClass:[NSArray class]] == NO) {
        self.categories = [NSArray array];
    }

    // online provider
    self.onlineProvider = [jsonEvent getJsonValue:@"onlineMeetingProvider"];

    // join url basic info
    self.joinUrl = [jsonEvent getJsonValue:@"onlineMeetingUrl"];
    if (IsValidString(self.joinUrl) == NO) {
        self.joinUrl = [jsonEvent getJsonValue:@"onlineMeeting" sub:@"joinUrl"];
    }

    // parse body specific urls
    if (IsValidString(self.joinUrl) == NO) {
    
        // teams
        if (IsValidString(self.joinUrl) == NO) {
            self.joinUrl = [OutlookEvent lookForOnlineUrlIn:jsonEvent
                                                withPattern:@"https://teams.microsoft.com/l/meetup-join/[^\"<]*"];
        }

        // webex
        if (IsValidString(self.joinUrl) == NO) {
            self.joinUrl = [OutlookEvent lookForOnlineUrlIn:jsonEvent
                                                withPattern:@"https://.*\\.webex.com/.*/j.php[^\"<]*"];
        }
        
        // webex room
        if (IsValidString(self.joinUrl) == NO) {
            self.joinUrl = [OutlookEvent lookForOnlineUrlIn:jsonEvent
                                                withPattern:@"https://.*\\.webex.com/join/[^\"<]*"];
        }
        
        // webex room
        if (IsValidString(self.joinUrl) == NO) {
            self.joinUrl = [OutlookEvent lookForOnlineUrlIn:jsonEvent
                                                withPattern:@"https://.*\\.webex.com/meet/[^\"<]*"];
        }
        
        // zoom
        if (IsValidString(self.joinUrl) == NO) {
            self.joinUrl = [OutlookEvent lookForOnlineUrlIn:jsonEvent
                                                withPattern:@"https://zoom.us/j/[^\"<]*"];
        }

        // run google meet last as it can embed other systems (zoom for instance)
        if (IsValidString(self.joinUrl) == NO) {
            self.joinUrl = [OutlookEvent lookForOnlineUrlIn:jsonEvent
                                                withPattern:@"https://meet.google.com/[^\"<]*"];
        }
        
        // check
        if (IsValidString(self.joinUrl) == NO) {
            [self setJoinUrl:nil];
        }
        
    }
    
    // debug
    //LOG("[EVENT] %s", self.joinUrl);

    // done
    return self;
    
}

+ (NSString*) lookForOnlineUrlIn:(NSDictionary*) jsonEvent withPattern:(NSString*) pattern {
    
    // first check in location
    NSString* location = [jsonEvent getJsonValue:@"location" sub:@"displayName"];
    if (location != nil) {
        NSString* url = [OutlookEvent extractUrlMatching:pattern from:location];
        if (url != nil) {
            return url;
        }
    }
    
    // look in body
    NSString* body = [jsonEvent getJsonValue:@"body" sub:@"content"];
    if (body != nil) {
        NSString *url = [OutlookEvent extractUrlMatching:pattern from:body];
        if (url != nil) {
            return url;
        }
    }
    
    // too bad
    return nil;
    
}

+ (NSString*) extractUrlMatching:(NSString*) pattern from:(NSString*) string {
    
    // build regex
    NSRegularExpression *regex = [NSRegularExpression
        regularExpressionWithPattern:pattern
        options:NSRegularExpressionCaseInsensitive
        error:nil];
    
    // find first
    __block NSString* url = nil;
    [regex enumerateMatchesInString:string
                            options:0
                              range:NSMakeRange(0, string.length)
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        
        // regex may go beyond ending quote so make sure we just keep what is needed
        url = [string substringWithRange:match.range];
        url = [[url componentsSeparatedByString:@"\""] objectAtIndex:0];
        *stop = YES;
    }];
    
    // done
    return url;
    
}

- (void) dealloc {
    
    [self.uid release];
    [self.title release];
    [self.categories release];
    [self.startTime release];
    [self.endTime release];
    [self.webLink release];
    [self.joinUrl release];
    
    [super dealloc];
    
}

- (NSString*) startTimeDesc {
    
    // now
    if ([self isInProgress]) {
        return @"Now";
    }
    
    // needed to compare
    NSDate* date = self.startTime;
    NSDate* reference = [[NSDate date] dateBySettingSeconds:0];
    NSTimeInterval interval = [date timeIntervalSinceDate:reference];
    
    // soon
    if (interval > 0 && interval <= EVENT_SOON_DELTA) {
        return [NSString stringWithFormat:@"In %@", [OutlookEvent formatDuration:interval longMinutes:YES]];
    }
    
    // get components
    NSDateComponents* nowComponents = [reference components];
    NSDateComponents* eventComponents = [date components];
    NSDateComponents* dayAfterComponents = [[reference dateByAddingTimeInterval:24*60*60] components];
    
    // need a date formatter
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    // final
    if (eventComponents.day == nowComponents.day) {
        return [NSString stringWithFormat:@"Today, %@", [dateFormatter stringFromDate:date]];
    } else if (eventComponents.day == dayAfterComponents.day) {
        return [NSString stringWithFormat:@"Tomorrow, %@", [dateFormatter stringFromDate:date]];
    } else {
        // default
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        return [dateFormatter stringFromDate:date];
    }
}

- (NSString*) durationDesc {
    
    // need an end time
    if (self.endTime == nil) {
        return nil;
    } else {
        return [OutlookEvent formatDuration:[self.endTime timeIntervalSinceDate:self.startTime] longMinutes:NO];
    }
}

+ (NSString*) formatDuration:(NSTimeInterval) duration longMinutes:(BOOL) longMinutes {
    
    duration = round(duration / 60);
    int hours = floor(duration / 60);
    int minutes = duration - hours * 60;
    if (hours == 0) {
        minutes = MAX(1, minutes);
        NSString* suffix = longMinutes ? (minutes == 1 ? @"minute" : @"minutes") : @"min";
        return [NSString stringWithFormat:@"%d %@", minutes, suffix];
    } else {
        if (minutes == 0) {
            return [NSString stringWithFormat:@"%dh", hours];
        } else {
            return [NSString stringWithFormat:@"%dh%02d", hours, minutes];
        }
    }

}

- (NSString*) timingDesc {
    
    // progress
    if ([self isInProgress]) {
        
        NSString* timeLeft = [OutlookEvent formatDuration:[self.endTime timeIntervalSinceMinuteStart] longMinutes:YES];
        if ([self isStarting]) {
            return [NSString stringWithFormat:@"Now, %@ left", timeLeft];
        } else {
            return [NSString stringWithFormat:@"%@ left", timeLeft];
        }
    }
    
    // needed
    NSString* startDesc = [self startTimeDesc];
    NSString* durationDesc = [self durationDesc];

    // else
    if (durationDesc == nil) {
        return startDesc;
    } else {
        return [NSString stringWithFormat:@"%@ (%@)", startDesc, durationDesc];
    }
    
}

- (NSTimeInterval) intervalWithNow {
    return round([self.startTime timeIntervalSinceMinuteStart]);
}

- (BOOL) isToday {
    return [self.startTime isToday];
}

- (BOOL) isTomorrow {
    return [self.startTime isTomorrow];
}

- (BOOL) canBeJoined {
    return [self isStarting] || [self isInProgress];
}

- (BOOL) isStarting {
    return [self.startTime isNowWithinMinutes:EVENT_STARTING_DELTA_MINUTES];
}

- (BOOL) isStarted {
    return [self.startTime isInPast];
}

- (BOOL) isEnded {
    return [self.endTime isInPast];
}

- (BOOL) isInProgress {
    return [self isStarted] == YES && [self isEnded] == NO;
}

- (BOOL) isSkype {
    return [self.onlineProvider isEqualToString:PROVIDER_SKYPE];
}

- (BOOL) isTeams {
    return
        [self.onlineProvider isEqualToString:PROVIDER_TEAMS] ||
        [self.joinUrl localizedCaseInsensitiveContainsString:@"teams.microsoft.com"];
}

- (BOOL) isWebEx {
    return
        /*[self.onlineProvider isEqualToString:PROVIDER_WEBEX] ||*/
        [self.joinUrl localizedCaseInsensitiveContainsString:@"webex.com"];
}

- (BOOL) isGoogleMeet {
    return
        /*[self.onlineProvider isEqualToString:PROVIDER_GOOGLE] |||*/
        [self.joinUrl localizedCaseInsensitiveContainsString:@"meet.google.com"];
}

- (BOOL) isZoom {
    return
        /*[self.onlineProvider isEqualToString:PROVIDER_ZOOM] |||*/
        [self.joinUrl localizedCaseInsensitiveContainsString:@"zoom.us"];
}

- (NSString*) directJoinUrl {
    
    // microsoft teams meeting
    if (self.isTeams) {
        NSString* directJoinUrl = self.joinUrl;
        directJoinUrl = [directJoinUrl stringByReplacingOccurrencesOfString:@"https://teams.microsoft.com/" withString:@"msteams:"];
        directJoinUrl = [directJoinUrl stringByAppendingString:@"&anon=true&launchAgent=join_launcher&type=meetup-join&directDl=true&msLaunch=true&enableMobilePage=true&fqdn=teams.microsoft.com"];
        return directJoinUrl;
    }
    
    // default
    return self.joinUrl;
    
}

- (NSComparisonResult) compare:(OutlookEvent*) other {
    
    // same
    if ([self.uid isEqualToString:other.uid]) {
        return NSOrderedSame;
    }
    
    // date is first
    NSComparisonResult dateCompare = [self.startTime compare:other.startTime];
    if (dateCompare != NSOrderedSame) {
        return dateCompare;
    }
    
    // busy first
    int diff = self.showAs - other.showAs;
    if (diff > 0) return NSOrderedAscending;
    if (diff < 0) return NSOrderedDescending;
    return NSOrderedSame;
    
}

+ (NSArray<OutlookEvent*>*) listFromJson:(NSArray<NSDictionary*>*) jsonArray {
    NSMutableArray<OutlookEvent*>* array = [NSMutableArray<OutlookEvent*> array];
    if (jsonArray != nil) {
        for (NSDictionary* dict in jsonArray) {
            OutlookEvent* event = [[OutlookEvent alloc] initWithJson:dict];
            [array addObject:event];
        }
    }
    return [NSArray arrayWithArray:array];
}


+ (OutlookEvent*) findSoonestEvent:(NSArray<OutlookEvent*>*) events busyOnly:(BOOL)busyOnly {
    
    // check
    if (events == nil || events.count == 0) {
        return nil;
    }
    
    // first exclude in progress
    OutlookEvent* soonest = [OutlookEvent findSoonestEvent:events busyOnly:busyOnly excludeInProgress:YES];
    
    // if no more event, let's try do display the possible current in progress meeting
    if (soonest == nil || [soonest isTomorrow]) {
        soonest = [OutlookEvent findSoonestEvent:events busyOnly:busyOnly excludeInProgress:NO];
    }
    
    // done
    return soonest;

}

+ (OutlookEvent*) findSoonestEvent:(NSArray*) events busyOnly:(BOOL)busyOnly excludeInProgress:(BOOL) excludeInProgress {

    // best
    OutlookEvent* soonest = nil;
    for (OutlookEvent* event in events) {
        
        // discard old events
        if ([event isEnded]) {
            continue;
        }
        
        // events started for too long do not count neither
        if (excludeInProgress) {
            if ([event intervalWithNow] < - EVENT_IN_PROGRESS_FOR) {
                continue;
            }
        }
        
        // only busy
        if (busyOnly && event.showAs != ShowAsBusy) {
            continue;
        }
        
        // first is best
        if (soonest == nil) {
            soonest = event;
            continue;
        }
        
        // get closest or if same date higher priority
        double eventDelta = fabs([event intervalWithNow]);
        double soonestDelta = fabs([soonest intervalWithNow]);
        double startDelta = fabs(eventDelta - soonestDelta);
        if (eventDelta < soonestDelta || (startDelta < 0.1 && event.showAs > soonest.showAs)) {
            //LOG("%@ %d > %@ %d (%f, %f)", event.title, event.showAs, soonest.title, soonest.showAs, eventDelta, soonestDelta);
            soonest = event;
        } else {
            //LOG("%@ %d < %@ %d (%f, %f)", event.title, event.showAs, soonest.title, soonest.showAs, eventDelta, soonestDelta);
        }
        
    }
    
    // done
    return soonest;

}

@end
