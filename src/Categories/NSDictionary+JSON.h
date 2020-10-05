//
//  NSDictionary+JSON.h
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/5/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary(JSON)

- (id) getJsonValue:(NSString*) key;
- (id) getJsonValue:(NSString*) key sub:(NSString*) subkey;
- (id) getJsonValue:(NSString*) key sub1:(NSString*) subkey1 sub2:(NSString*) subkey2;

@end

NS_ASSUME_NONNULL_END
