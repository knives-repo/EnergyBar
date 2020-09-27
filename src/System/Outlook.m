//
//  Outlook.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/26/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "Outlook.h"

#define IsValid(x) (x != nil && [x isKindOfClass:[NSNull class]] == NO)

#define CALENDAR_LIST_OFFSET_START -10*60
#define CALENDAR_LIST_OFFSET_END 24*60*60
#define CALENDAR_CLOSE_EVENT_DELTA 2*60*60

NSString* kClientID = @"82ac6221-a570-439c-a965-040443a5036c";
NSString* kAuthority = @"https://login.microsoftonline.com/common";
NSString* kRedirectUri = @"msauth.billziss.EnergyBar://auth";

@interface Outlook()

@property (retain) NSString* accessToken;
@property (retain) MSALPublicClientApplication* applicationContext;
@property (retain) MSALWebviewParameters* webViewParameters;

@end

@implementation Outlook

- (NSArray*)scopes {
    return @[ @"User.Read", @"Calendars.Read" ];
}

- (void)loadCurrentAccount:(voidCompletionBlock) completionBlock {
    
    // init stuff
    NSURL* url = [NSURL URLWithString:kAuthority];
    MSALAADAuthority* authority = [[MSALAADAuthority alloc] initWithURL:url error:nil];
    MSALPublicClientApplicationConfig* msalConfiguration = [[MSALPublicClientApplicationConfig alloc]
                                                            initWithClientId:kClientID
                                                            redirectUri:kRedirectUri
                                                            authority:authority];
    self.applicationContext = [[MSALPublicClientApplication alloc] initWithConfiguration:msalConfiguration error:nil];
    self.webViewParameters = [[MSALWebviewParameters alloc] init];
    
    // now look for it
    MSALParameters* msalParameters = [[MSALParameters alloc] init];
    [msalParameters setCompletionBlockQueue:dispatch_get_main_queue()];
    [self.applicationContext getCurrentAccountWithParameters:msalParameters completionBlock:^(MSALAccount * _Nullable account, MSALAccount * _Nullable previousAccount, NSError * _Nullable error) {

        if (error != nil) {
            NSLog(@"[LOAD] Error: %@", error);
        }
        if (account == nil) {
            NSLog(@"[LOAD] Empty result");
        }
        
        if (error == nil && account != nil) {
            NSLog(@"[LOAD] Success!");
            self.currentAccount = account;
            self.accessToken = nil;
        }
        
        // done
        if (completionBlock != nil) {
            completionBlock();
        }

    }];
    
}

- (void)acquireTokenSilently:(void (^)(void)) completionBlock {
    
    // need an account for this
    if (self.currentAccount == nil) {
        NSLog(@"[SILENT] Redirect to Interactive");
        [self acquireTokenInteractively:completionBlock];
        return;
    }
    
    // try silent
    MSALSilentTokenParameters* silentTokenParameters = [[MSALSilentTokenParameters alloc]
                                                        initWithScopes:[self scopes]
                                                        account:self.currentAccount];
    [self.applicationContext acquireTokenSilentWithParameters:silentTokenParameters completionBlock:^(MSALResult * _Nullable result, NSError * _Nullable error) {
        
        if (error != nil) {
            if (error.domain == MSALErrorDomain) {
                if (error.code == MSALErrorInteractionRequired) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"[SILENT] Interaction required");
                        [self acquireTokenInteractively:completionBlock];
                        return;
                    });
                }
            }
            NSLog(@"[SILENT] Error: %@", error);
        }
        if (result == nil) {
            NSLog(@"[SILENT] Empty result");
        }
        
        if (error == nil && result != nil) {
            NSLog(@"[SILENT] Success!");
            self.currentAccount = result.account;
            self.accessToken = result.accessToken;
        }
        
        // done
        if (completionBlock != nil) {
            completionBlock();
        }

    }];
    
}

- (void)acquireTokenInteractively:(void (^)(void)) completionBlock {

    // do it
    MSALInteractiveTokenParameters* interactiveTokenParameters = [[MSALInteractiveTokenParameters alloc]
                                                                  initWithScopes:[self scopes]
                                                                  webviewParameters:self.webViewParameters];
    [interactiveTokenParameters setPromptType:MSALPromptTypeSelectAccount];
    [self.applicationContext acquireTokenWithParameters:interactiveTokenParameters completionBlock:^(MSALResult * _Nullable result, NSError * _Nullable error) {
        
        if (error != nil) {
            NSLog(@"[INTER] Error: %@", error);
        }
        if (result == nil) {
            NSLog(@"[INTER] Empty result");
        }
        
        if (error == nil && result != nil) {
            NSLog(@"[INTER] Success!");
            self.currentAccount = result.account;
            self.accessToken = result.accessToken;
        }
        
        // done
        if (completionBlock != nil) {
            completionBlock();
        }
        
    }];

}

- (void)getContent:(NSString*) uri withHeaders:(NSDictionary*) headers completionBlock:(void (^)(NSDictionary*)) completionBlock {
    
    // need to a token
    if (self.accessToken == nil) {
        NSLog(@"[CONTENT] No token");
        completionBlock(nil);
        return;
    }
    
    // prepare basic
    NSURL* url = [NSURL URLWithString:uri];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSString* bearer = [NSString stringWithFormat:@"Bearer %@", self.accessToken];
    [request addValue:bearer forHTTPHeaderField:@"Authorization"];
    
    // add custom headers
    if (headers != nil) {
        for (id key in [headers allKeys]) {
            [request addValue:[headers objectForKey:key] forHTTPHeaderField:key];
        }
    }
    
    // prepare task
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"[CONTENT] Error: %@", error);
            completionBlock(nil);
            return;
        }
        if (response == nil) {
            NSLog(@"[CONTENT] No response");
            completionBlock(nil);
            return;
        }
        NSError *e = nil;
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];
        completionBlock(jsonObject);
    }];
    
    // start
    [task resume];
}

- (void) signIn:(JsonCompletionBlock) completionBlock {

    NSString* uri = @"https://graph.microsoft.com/v1.0/me";
    [self acquireTokenSilently:^{
        [self getContent:uri withHeaders:nil completionBlock:^(NSDictionary* jsonObject) {
            if (completionBlock != nil) {
                completionBlock(jsonObject);
            }
        }];
    }];

}

- (void) signOut:(voidCompletionBlock) completionBlock {
    
    MSALSignoutParameters* signoutParameters = [[MSALSignoutParameters alloc] initWithWebviewParameters:self.webViewParameters];
    [signoutParameters setSignoutFromBrowser:YES];
    [self.applicationContext signoutWithAccount:self.currentAccount signoutParameters:signoutParameters completionBlock:^(BOOL success, NSError * _Nullable error) {

        if (error != nil) {
            NSLog(@"[SIGNOUT] Error: %@", error);
        }
        
        if (error == nil && success == YES) {
            NSLog(@"[SIGNOUT] Success!");
            self.currentAccount = nil;
            self.accessToken = nil;
        }
        
        if (completionBlock != nil) {
            completionBlock();
        }

    }];
}


- (void) getCalendarEvents:(JsonCompletionBlock) completionBlock {
    
    // build url
    NSString* path = @"v1.0/me/calendar/events";
    NSString* select = @"$select=organizer,start,showAs,subject,body,onlineMeeting,onlineMeetingUrl,webLink";
    NSString* orderBy = @"$orderBy=start/dateTime,showAs";
    
    // filter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm"];
    NSDate* now = [[NSDate alloc] init];
    NSDate* start = [now dateByAddingTimeInterval:CALENDAR_LIST_OFFSET_START];
    NSDate* end = [now dateByAddingTimeInterval:CALENDAR_LIST_OFFSET_END];
    NSString* filter = [NSString stringWithFormat:@"$filter=start/dateTime%%20ge%%20'%@'%%20and%%20start/dateTime%%20lt%%20'%@'",
                        [dateFormatter stringFromDate:start], [dateFormatter stringFromDate:end]];

    // done
    NSString* uri = [NSString stringWithFormat:@"https://graph.microsoft.com/%@?%@&%@&%@", path, filter, select, orderBy];

    // timezone
    NSTimeZone* timezone = [NSTimeZone localTimeZone];
    NSDictionary* headers = @{
        @"Prefer": [NSString stringWithFormat:@"outlook.timezone=\"%@\"", timezone.name]
    };
    
    // now do it
    [self acquireTokenSilently:^{
        [self getContent:uri withHeaders:headers completionBlock:^(NSDictionary* jsonObject) {
            NSLog(@"%@", jsonObject);
            completionBlock(jsonObject);
        }];
    }];

}

@end

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

- (id) initWithJson:(NSDictionary*) jsonEvent {
    
    // start with easy one
    self = [super init];
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
    
    // join url
    self.joinUrl = [jsonEvent getJsonValue:@"onlineMeetingUrl"];
    if (IsValid(self.joinUrl) == NO) {
        self.joinUrl = [jsonEvent getJsonValue:@"onlineMeeting" sub:@"joinUrl"];
    }
    if (IsValid(self.joinUrl) == NO) {

        // parse body for teams
        NSString* body = [jsonEvent getJsonValue:@"body" sub:@"content"];
        NSRange rangeStart = [body rangeOfString:@"https://teams.microsoft.com/l/meetup-join/"];
        if (rangeStart.location != NSNotFound) {
            NSRange rangeEnd = [body rangeOfString:@"\"" options:0 range:NSMakeRange(rangeStart.location, body.length - rangeStart.location)];
            if (rangeEnd.location != NSNotFound) {
                self.joinUrl = [body substringWithRange:NSMakeRange(rangeStart.location, rangeEnd.location - rangeStart.location)];
            }
        }
    }

    // done
    return self;
    
}

- (NSString*) startTimeDesc {
    
    // debug
    NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
    NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
    [components setYear:2020];
    [components setMonth:9];
    [components setDay:27];
    [components setHour:15];
    [components setHour:20];
    NSDate* now = [calendar dateFromComponents:components];

    
    // needed to compare
    //NSDate* now = [[NSDate alloc] initW
    NSTimeInterval interval = [self.startTime timeIntervalSinceDate:now];
    
    // tell time diff
    if (interval <= CALENDAR_CLOSE_EVENT_DELTA) {
        
        int minutes = interval / 60;
        int hours = minutes / 60;
        minutes = minutes - hours * 60;
        if (hours == 0) {
            return [NSString stringWithFormat:@"In %d minutes", minutes];
        } else {
            return [NSString stringWithFormat:@"In %dh%d", hours, minutes];
        }
        
    }
    
    // need a time formatter
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    // get components
    NSDateComponents* nowComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:now];
    NSDateComponents* eventComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:self.startTime];
    
    // if same day
    if (eventComponents.day == nowComponents.day) {
        return [NSString stringWithFormat:@"Today, %@", [dateFormatter stringFromDate:self.startTime]];
    } else if (eventComponents.day == nowComponents.day + 1) {
        return [NSString stringWithFormat:@"Tomorrow, %@", [dateFormatter stringFromDate:self.startTime]];
    } else {
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        return [dateFormatter stringFromDate:self.startTime];
    }
}

@end
