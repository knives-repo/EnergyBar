//
//  NSDictionary+JSON.m
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/5/20.
//  Copyright © 2020 Nicolas Bonamy. All rights reserved.
//

#import "NSDictionary+JSON.h"

@implementation NSDictionary(JSON)

- (id) getJsonValue:(NSString*) key {
    id value = [self objectForKey:key];
    return (IsValid(value) ? value : nil);
}

- (id) getJsonValue:(NSString*) key sub:(NSString*) subkey {
    NSDictionary* dict = [self objectForKey:key];
    return (IsValid(dict) ? [dict getJsonValue:subkey] : nil);
}

- (id) getJsonValue:(NSString*) key sub1:(NSString*) subkey1 sub2:(NSString*) subkey2 {
    NSDictionary* dict = [self objectForKey:key];
    if (IsValid(dict)) {
        dict = [dict objectForKey:subkey1];
        if (IsValid(dict)) {
            return [dict getJsonValue:subkey2];
        }
    }
    return nil;
}

@end
