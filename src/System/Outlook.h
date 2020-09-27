//
//  Outlook.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 9/26/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSAL.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ _Nullable voidCompletionBlock)(void);
typedef void (^ _Nullable JsonCompletionBlock)(NSDictionary*);

@interface Outlook : NSObject

@property (retain,nullable) MSALAccount* currentAccount;

- (void)loadCurrentAccount:(voidCompletionBlock) completionBlock;
- (void)signIn:(JsonCompletionBlock) completionBlock;
- (void)signOut:(voidCompletionBlock) completionBlock;
- (void)getCalendarEvents:(JsonCompletionBlock) completionBlock;

@end

NS_ASSUME_NONNULL_END
