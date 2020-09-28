//
//  Outlook.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/26/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import "Outlook.h"

#define CALENDAR_LIST_OFFSET_START -10*60
#define CALENDAR_LIST_OFFSET_END 24*60*60
#define CALENDAR_SHOW_TOMMOROW_HOUR_THRESHOLD 15

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
    NSString* path = @"v1.0/me/calendar/calendarView";
    NSString* select = @"$select=organizer,start,showAs,subject,body,onlineMeeting,onlineMeetingUrl,webLink";
    NSString* orderBy = @"$orderBy=start/dateTime,showAs";
    NSString* count = @"$top=50";
    
    // filter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm'Z'"];
    NSDate* now = [NSDate date];
    NSDate* start = [now dateByAddingTimeInterval:CALENDAR_LIST_OFFSET_START];
    
    // end date: midnight if before
    NSDate* end = [now dateByAddingTimeInterval:CALENDAR_LIST_OFFSET_END];
    if ([[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:now].hour < CALENDAR_SHOW_TOMMOROW_HOUR_THRESHOLD) {
        end = [[NSCalendar currentCalendar] dateBySettingHour:23 minute:59 second:59 ofDate:now options:0];
    }
    
    // filter
    NSString* filter = [NSString stringWithFormat:@"startDateTime=%@&endDateTime=%@",
                        [dateFormatter stringFromDate:start], [dateFormatter stringFromDate:end]];
    NSLog(@"%@", filter);

    // done
    NSString* uri = [NSString stringWithFormat:@"https://graph.microsoft.com/%@?%@&%@&%@&%@", path, filter, select, orderBy, count];
    //NSLog(@"%@", uri);

    // timezone
    NSTimeZone* timezone = [NSTimeZone localTimeZone];
    NSDictionary* headers = @{
        @"Prefer": [NSString stringWithFormat:@"outlook.timezone=\"%@\"", timezone.name]
    };
    
    // now do it
    [self acquireTokenSilently:^{
        [self getContent:uri withHeaders:headers completionBlock:^(NSDictionary* jsonObject) {
            //NSLog(@"%@", jsonObject);
            completionBlock(jsonObject);
        }];
    }];

}

@end
