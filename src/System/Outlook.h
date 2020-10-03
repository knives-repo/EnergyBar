//
//  Outlook.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/26/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSAL.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ _Nullable voidCompletionBlock)(void);
typedef void (^ _Nullable JsonCompletionBlock)(NSDictionary*);

typedef enum {
    ShowNever,
    ShowAlways,
    ShowEvening
} ShowTomorrow;

@interface Outlook : NSObject

@property (retain,nullable) MSALAccount* currentAccount;

- (void)loadCurrentAccount:(voidCompletionBlock) completionBlock;
- (void)signIn:(JsonCompletionBlock) completionBlock;
- (void)signOut:(voidCompletionBlock) completionBlock;

//- (void)getCategories:(JsonCompletionBlock) completionBlock;
- (void)getCalendarEvents:(ShowTomorrow) showTomorrow completionBlock:(JsonCompletionBlock) completionBlock;

@end

NS_ASSUME_NONNULL_END
