//
//  main.m
//  OutlookTests
//
//  Created by Nicolas Bonamy on 9/27/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OutlookEvent.h"

NSDate* dateWithOffset(NSTimeInterval interval) {
	NSDate* now = [[NSDate alloc] init];
	return [now dateByAddingTimeInterval:interval];
}

void verify(NSString* actual, NSString* expected) {
	if ([expected isEqual:actual] == NO) {
		NSLog(@"\nExpected: %@\n  Actual: %@", expected, actual);
		//assert(FALSE);
	} else {
		NSLog(@"OK");
	}
}

void test(int offsetInMinutes, NSString* expected) {
	
	// fix reference
	NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
	NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
	[components setYear:2020];
	[components setMonth:9];
	[components setDay:27];
	[components setHour:15];
	[components setHour:21];
	[components setMinute:00];
	NSDate* reference = [calendar dateFromComponents:components];

	// offset and compare
	NSDate* date = [reference dateByAddingTimeInterval:offsetInMinutes*60];
	verify([OutlookEvent dateDiffDescriptionBetween:reference and:date], expected);
}

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		
		// now
		test(-10, @"Now");
		test(-5, @"Now");
		test(-0, @"Now");
		test(3, @"Now");
		
		// soon
		test(4, @"In 4 minutes");
		test(10, @"In 10 minutes");
		test(59, @"In 59 minutes");
		test(60, @"In 1h");
		test(62, @"In 1h02");
		test(90, @"In 1h30");
		test(119, @"In 1h59");
		
		// later
		test(135, @"Today, 23:15");
		test(195, @"Tomorrow, 00:15");
		
		// much later
		test(24*60, @"Sep 28, 2020 at 21:00");

		
	}
	return 0;
}
