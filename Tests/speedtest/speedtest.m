/*
 * Diff Match and Patch
 *
 * Copyright 2013 geheimwerk.de.
 * http://code.google.com/p/google-diff-match-patch/
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Author: fraser@google.com (Neil Fraser)
 * ObjC port: jan@geheimwerk.de (Jan Weiß)
 */

#import <Foundation/Foundation.h>

#import "DiffMatchPatch.h"
#import "TestUtilities.h"


void diff_measureTimeForDiff(NSString *text1, NSString *text2, NSString *aDescription)
{
	NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
	NSArray *diffs = diff_diffsBetweenTextsWithOptions(text1, text2, YES, 0.0);
	NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
	
	if(diffs.count > 0) {
		NSLog(@"%@ Elapsed time: %.4lf", aDescription, (double)duration);
	} else {
		NSLog(@"%@ Failed to generate diffs", aDescription);
	}
}

int main(int argc, const char *argv[])
{
	@autoreleasepool {
	
	NSString *text1FilePath = @"Speedtest1.txt";
	NSString *text2FilePath = @"Speedtest2.txt";
	
	NSArray *cliArguments = [[NSProcessInfo processInfo] arguments];
	
	if ([cliArguments count] == 3) {
		text1FilePath = [cliArguments objectAtIndex:1];
		text2FilePath = [cliArguments objectAtIndex:2];
	}
	
	NSString *text1 = diff_stringForFilePath(text1FilePath);
	NSString *text2 = diff_stringForFilePath(text2FilePath);
	
	NSString *aDescription;
	
#ifdef ENABLE_PERFORMANCE_TABLE_OUTPUT
	NSUInteger limit;
	for (int i = 8; i <= 24; i++) {
		limit = pow(2.0, i);
		if ( (limit > text1.length) || (limit > text2.length) ) {
			break;
		}
		
		aDescription = [NSString stringWithFormat:@"%8lu unichars, ", (unsigned long)limit];
		diff_measureTimeForDiff([text1 substringToIndex:limit], [text2 substringToIndex:limit], aDescription);
	}
#endif
	
	aDescription = [NSString stringWithFormat:@"%8lu unichars, ", (unsigned long)MAX(text1.length, text2.length)];
	diff_measureTimeForDiff(text1, text2, aDescription);
	
	}
	
	return 0;
}
