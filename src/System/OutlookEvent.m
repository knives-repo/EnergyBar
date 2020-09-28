//
//  OutlookEvent.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/27/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "OutlookEvent.h"

#define IsValid(x) (x != nil && [x isKindOfClass:[NSNull class]] == NO)
#define IsValidString(x) (IsValid(x) && [x length] > 0)

#define EVENT_NOW_DELTA 3*60
#define EVENT_CURRENT_DELTA 5*60
#define EVENT_SOON_DELTA 1*60*60
#define EVENT_CLOSE_DELTA 4*60*60

@interface NSDictionary(Json)
- (NSString*) getJsonValue:(NSString*) key;
- (NSString*) getJsonValue:(NSString*) key sub:(NSString*) subkey;
@end

@implementation NSDictionary(Json)

- (NSString*) getJsonValue:(NSString*) key {
    id value = [self objectForKey:key];
    return (IsValid(value) ? value : nil);
}

- (NSString*) getJsonValue:(NSString*) key sub:(NSString*) subkey {
    NSDictionary* dict = [self objectForKey:key];
    return (IsValid(dict) ? [dict getJsonValue:subkey] : nil);
}

@end

@implementation OutlookEvent

- (NSString*) description {
    return [NSString stringWithFormat:@"%@: %@", self.startTime, self.title];
}

- (id) initWithJson:(NSDictionary*) jsonEvent {
    
    // start with easy one
    self = [super init];
    self.uid = [jsonEvent getJsonValue:@"id"];
    self.title = [jsonEvent getJsonValue:@"subject"];
    self.webLink = [jsonEvent getJsonValue:@"webLink"];
    
    // show as
    self.showAs = Unknown;
    NSString* jsonShowAs = [jsonEvent getJsonValue:@"showAs"];
    if ([jsonShowAs caseInsensitiveCompare:@"free"] == NSOrderedSame) {
        self.showAs = Free;
    } else if ([jsonShowAs caseInsensitiveCompare:@"busy"] == NSOrderedSame) {
        self.showAs = Busy;
    } else if ([jsonShowAs caseInsensitiveCompare:@"tentative"] == NSOrderedSame) {
        self.showAs = Tentative;
    } else if ([jsonShowAs caseInsensitiveCompare:@"oof"] == NSOrderedSame) {
        self.showAs = OutOfOffice;
    } else if ([jsonShowAs caseInsensitiveCompare:@"workingelsewhere"] == NSOrderedSame) {
        self.showAs = Busy;
    }
    
    // date: 2020-09-28T01:00:00.0000000
    NSString* jsonDate = [jsonEvent getJsonValue:@"start" sub:@"dateTime"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
    self.startTime = [dateFormatter dateFromString:jsonDate];
    
    // join url basic info
    self.joinUrl = [jsonEvent getJsonValue:@"onlineMeetingUrl"];
    if (IsValidString(self.joinUrl) == NO) {
        self.joinUrl = [jsonEvent getJsonValue:@"onlineMeeting" sub:@"joinUrl"];
    }
    
    // parse body for teams
    if (IsValidString(self.joinUrl) == NO) {
        NSString* body = [jsonEvent getJsonValue:@"body" sub:@"content"];
        NSRange rangeStart = [body rangeOfString:@"https://teams.microsoft.com/l/meetup-join/"];
        if (rangeStart.location != NSNotFound) {
            NSRange rangeEnd = [body rangeOfString:@"\"" options:0 range:NSMakeRange(rangeStart.location, body.length - rangeStart.location)];
            if (rangeEnd.location != NSNotFound) {
                self.joinUrl = [body substringWithRange:NSMakeRange(rangeStart.location, rangeEnd.location - rangeStart.location)];
            }
        }
    }
    
    // parse body for webex
    if (IsValidString(self.joinUrl) == NO) {
        NSString* body = [jsonEvent getJsonValue:@"body" sub:@"content"];
        NSRegularExpression *regex = [NSRegularExpression
            regularExpressionWithPattern:@"https://.*\\.webex.com/.*/j.php[^\"]*"
            options:NSRegularExpressionCaseInsensitive
            error:nil];
        [regex enumerateMatchesInString:body options:0 range:NSMakeRange(0, body.length)
                             usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
            self.joinUrl = [[[body substringWithRange:match.range] componentsSeparatedByString:@"\""] objectAtIndex:0];
            *stop = YES;
        }];

    }
    
    // check
    if (IsValidString(self.joinUrl) == NO) {
        [self setJoinUrl:nil];
    }

    // done
    return self;
    
}

- (NSString*) startTimeDesc {
    return [OutlookEvent dateDiffDescriptionBetween:[NSDate date] and:self.startTime];
}

- (NSTimeInterval) intervalWithNow {
    NSDate* now = [NSDate date];
    return [self.startTime timeIntervalSinceDate:now];
}

- (BOOL) isCurrent {
    return [self intervalWithNow] <= EVENT_CURRENT_DELTA;
}

- (BOOL) isTeams {
    return [self.joinUrl localizedCaseInsensitiveContainsString:@"teams.microsoft.com"];
}

- (BOOL) isWebEx {
    return [self.joinUrl localizedCaseInsensitiveContainsString:@"webex.com"];
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


+ (NSArray*) listFromJson:(NSArray*) jsonArray {
    NSMutableArray* array = [NSMutableArray array];
    if (jsonArray != nil) {
        for (NSDictionary* dict in jsonArray) {
            OutlookEvent* event = [[OutlookEvent alloc] initWithJson:dict];
            [array addObject:event];
        }
    }
    return [NSArray arrayWithArray:array];
}

+ (NSString*) dateDiffDescriptionBetween:(NSDate*) reference and:(NSDate*) date {
    
    // needed to compare
    NSTimeInterval interval = [date timeIntervalSinceDate:reference];
    
    // now
    if (interval <= EVENT_NOW_DELTA) {
        return @"Now";
    }
    
    // soon
    if (interval <= EVENT_SOON_DELTA) {
        
        int minutes = interval / 60;
        int hours = minutes / 60;
        minutes = minutes - hours * 60;
        if (hours == 0) {
            return [NSString stringWithFormat:@"In %d minutes", minutes];
        } else if (minutes == 0) {
            return [NSString stringWithFormat:@"In %dh", hours];
        } else {
            return [NSString stringWithFormat:@"In %dh%02d", hours, minutes];
        }
        
    }
    
    // get components
    NSDateComponents* nowComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:reference];
    NSDateComponents* eventComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:date];
    
    // need a date formatter
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    // final
    if (eventComponents.day == nowComponents.day) {
        return [NSString stringWithFormat:@"Today, %@", [dateFormatter stringFromDate:date]];
    } else if (eventComponents.day == nowComponents.day + 1) {
        return [NSString stringWithFormat:@"Tomorrow, %@", [dateFormatter stringFromDate:date]];
    } else {
        // default
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        return [dateFormatter stringFromDate:date];
    }

}

+ (OutlookEvent*) findSoonestEvent:(NSArray*) events busyOnly:(BOOL)busyOnly {
    
    // check
    if (events == nil || events.count == 0) {
        return nil;
    }
    
    // best
    OutlookEvent* soonest = nil;
    for (OutlookEvent* event in events) {
        
        // discard old events
        NSTimeInterval interval = [event intervalWithNow];
        if (interval < -EVENT_CURRENT_DELTA) {
            continue;
        }
        
        // only busy
        if (busyOnly && event.showAs != Busy) {
            continue;
        }
        
        // first is best
        if (soonest == nil) {
            soonest = event;
            continue;
        }
        
        // if same date
        if ([event.startTime isEqualToDate:soonest.startTime] == NO) {
            break;
        }
        
        // compare show As
        int delta = event.showAs - soonest.showAs;
        if (delta > 0) {
            soonest = event;
        }
        
    }
    
    // done
    return soonest;

}

@end
