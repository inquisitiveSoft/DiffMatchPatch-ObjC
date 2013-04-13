//
//  DiffMatchPatchTests.m
//  DiffMatchPatchTests
//
//  Created by Harry Jordan on 12/04/2013.
//  Copyright (c) 2013 Harry Jordan. All rights reserved.
//	Apache 2 license
//


#import "DiffMatchPatchTests.h"

#import "DiffMatchPatch.h"
#import "DiffMatchPatchInternals.h"
#import "DiffMatchPatchCFUtilities.h"


@implementation DiffMatchPatchTests


- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}


- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}



- (void)test_commonPrefixTest
{
	// Detect any common suffix.
	// Null case.
	CFIndex prefixIndex = diff_commonPrefix((__bridge CFStringRef)@"abc", (__bridge CFStringRef)@"xyz");
	STAssertTrue(prefixIndex == 0, @"Common suffix null case failed.");
	
	// Non-null case.
	prefixIndex = diff_commonPrefix((__bridge CFStringRef)@"1234abcdef", (__bridge CFStringRef)@"1234xyz");
	STAssertTrue(prefixIndex == 4, @"Common suffix non-null case failed.");
	
	// Whole case.
	prefixIndex = diff_commonPrefix((__bridge CFStringRef)@"1234", (__bridge CFStringRef)@"1234xyz");
	STAssertTrue(prefixIndex == 4, @"Common suffix whole case failed.");
}


- (void)test_diff_commonSuffixTest
{
	// Detect any common suffix.
	// Null case.
	CFIndex prefixIndex = diff_commonSuffix((__bridge CFStringRef)@"abc", (__bridge CFStringRef)@"xyz");
	STAssertTrue(prefixIndex == 0, @"Detect any common suffix. Null case.");
	
	// Non-null case.
	prefixIndex = diff_commonSuffix((__bridge CFStringRef)@"abcdef1234", (__bridge CFStringRef)@"xyz1234");
	STAssertTrue(prefixIndex == 4, @"Detect any common suffix. Non-null case.");
	
	// Whole case.
	prefixIndex = diff_commonSuffix((__bridge CFStringRef)@"1234", (__bridge CFStringRef)@"xyz1234");
	STAssertTrue(prefixIndex == 4, @"Detect any common suffix. Whole case.");
}


- (void)test_diff_commonOverlapTest
{
	// Detect any suffix/prefix overlap.
	// Null case.
	CFIndex prefixIndex = diff_commonOverlap((__bridge CFStringRef)@"", (__bridge CFStringRef)@"abcd");
	STAssertTrue(prefixIndex == 0, @"Detect any suffix/prefix overlap. Null case.");
	
	// Whole case.
	prefixIndex = diff_commonOverlap((__bridge CFStringRef)@"abc", (__bridge CFStringRef)@"abcd");
	STAssertTrue(prefixIndex == 3, @"Detect any suffix/prefix overlap. Whole case.");
	
	// No overlap.
	prefixIndex = diff_commonOverlap((__bridge CFStringRef)@"123456", (__bridge CFStringRef)@"abcd");
	STAssertTrue(prefixIndex == 0, @"Detect any suffix/prefix overlap. No overlap.");
	
	// Overlap.
	prefixIndex = diff_commonOverlap((__bridge CFStringRef)@"123456xxx", (__bridge CFStringRef)@"xxxabcd");
	STAssertTrue(prefixIndex == 3, @"Detect any suffix/prefix overlap. Overlap.");
	
	// Unicode.
	// Some overly clever languages (C#) may treat ligatures as equal to their 
	// component letters.  E.g. U+FB01 == 'fi'
	prefixIndex = diff_commonOverlap((__bridge CFStringRef)@"fi", (__bridge CFStringRef)@"\U0000fb01i");
	STAssertTrue(prefixIndex == 0, @"Detect any suffix/prefix overlap. Unicode.");
}


- (void)test_diff_halfmatchTest
{
	//	Diff_Timeout = 1;
	
	// No match.
	STAssertNil((__bridge_transfer NSArray *)diff_halfMatchFromStrings((__bridge CFStringRef)@"1234567890", (__bridge CFStringRef)@"abcdef"), @"No match #1.");
	
	STAssertNil((__bridge_transfer NSArray *)diff_halfMatchFromStrings((__bridge CFStringRef)@"12345", (__bridge CFStringRef)@"23"), @"No match #2.");
	
	// Single Match.
	NSArray *expectedResult = @[@"12", @"90", @"a", @"z", @"345678"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchFromStrings((__bridge CFStringRef)@"1234567890", (__bridge CFStringRef)@"a345678z"), @"Single Match #1.");
	
	expectedResult = @[@"a", @"z", @"12", @"90", @"345678"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchFromStrings((__bridge CFStringRef)@"a345678z", (__bridge CFStringRef)@"1234567890"), @"Single Match #2.");
	
	expectedResult = @[@"abc", @"z", @"1234", @"0", @"56789"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchFromStrings((__bridge CFStringRef)@"abc56789z", (__bridge CFStringRef)@"1234567890"), @"Single Match #3.");
	
	expectedResult = @[@"a", @"xyz", @"1", @"7890", @"23456"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchFromStrings((__bridge CFStringRef)@"a23456xyz", (__bridge CFStringRef)@"1234567890"), @"Single Match #4.");
	
	// Multiple Matches.
	expectedResult = @[@"12123", @"123121", @"a", @"z", @"1234123451234"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchFromStrings((__bridge CFStringRef)@"121231234123451234123121", (__bridge CFStringRef)@"a1234123451234z"), @"Multiple Matches #1.");
	
	expectedResult = @[@"", @"-=-=-=-=-=", @"x", @"", @"x-=-=-=-=-=-=-="];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchFromStrings((__bridge CFStringRef)@"x-=-=-=-=-=-=-=-=-=-=-=-=", (__bridge CFStringRef)@"xx-=-=-=-=-=-=-="), @"Multiple Matches #2.");
	
	expectedResult = @[@"-=-=-=-=-=", @"", @"", @"y", @"-=-=-=-=-=-=-=y"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchFromStrings((__bridge CFStringRef)@"-=-=-=-=-=-=-=-=-=-=-=-=y", (__bridge CFStringRef)@"-=-=-=-=-=-=-=yy"), @"Multiple Matches #3.");
	
	// Non-optimal halfMatch.
	// Optimal diff would be -q+x=H-i+e=lloHe+Hu=llo-Hew+y not -qHillo+x=HelloHe-w+Hulloy
	expectedResult = @[@"qHillo", @"w", @"x", @"Hulloy", @"HelloHe"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchFromStrings((__bridge CFStringRef)@"qHilloHelloHew", (__bridge CFStringRef)@"xHelloHeHulloy"), @"Non-optimal halfmatch.");
	
	// Unlike Jan's version diff_halfMatchOfFirstString(...) no longer
	// has a diffTimeout parameter. Instead the onus is on the caller
	// to decide whether the trade offs of the halfMatch technique..
	// a faster sub-optimal match is worth it.
}


- (void)test_diff_linesToCharsTest
{
	// Convert lines down to characters.
	NSMutableArray *tmpVector = [NSMutableArray array];  // Array of NSString objects.
	[tmpVector addObject:@""];
	[tmpVector addObject:@"alpha\n"];
	[tmpVector addObject:@"beta\n"];
	
	NSArray *result = diff_linesToCharsForStrings(@"alpha\nbeta\nalpha\n", @"beta\nalpha\nbeta\n");
	STAssertEqualObjects(@"\001\002\001", [result objectAtIndex:0], @"Shared lines #1.");
	STAssertEqualObjects(@"\002\001\002", [result objectAtIndex:1], @"Shared lines #2.");
	STAssertEqualObjects(tmpVector, (NSArray *)[result objectAtIndex:2], @"Shared lines #3.");
	
	[tmpVector removeAllObjects];
	[tmpVector addObject:@""];
	[tmpVector addObject:@"alpha\r\n"];
	[tmpVector addObject:@"beta\r\n"];
	[tmpVector addObject:@"\r\n"];
	
	result = diff_linesToCharsForStrings(@"", @"alpha\r\nbeta\r\n\r\n\r\n");
	STAssertEqualObjects(@"", [result objectAtIndex:0], @"Empty string and blank lines #1.");
	STAssertEqualObjects(@"\001\002\003\003", [result objectAtIndex:1], @"Empty string and blank lines #2.");
	STAssertEqualObjects(tmpVector, (NSArray *)[result objectAtIndex:2], @"Empty string and blank lines #3.");
	
	[tmpVector removeAllObjects];
	[tmpVector addObject:@""];
	[tmpVector addObject:@"a"];
	[tmpVector addObject:@"b"];
	
	result = diff_linesToCharsForStrings(@"a", @"b");
	STAssertEqualObjects(@"\001", [result objectAtIndex:0], @"No linebreaks #1.");
	STAssertEqualObjects(@"\002", [result objectAtIndex:1], @"No linebreaks #2.");
	STAssertEqualObjects(tmpVector, (NSArray *)[result objectAtIndex:2], @"No linebreaks #3.");
	
	// More than 256 to reveal any 8-bit limitations.
	unichar n = 300;
	[tmpVector removeAllObjects];
	NSMutableString *lines = [NSMutableString string];
	NSMutableString *chars = [NSMutableString string];
	
	NSString *currentLine;
	for(unichar x = 1; x < n + 1; x++) {
		currentLine = [NSString stringWithFormat:@"%d\n", (int)x];
		[tmpVector addObject:currentLine];
		[lines appendString:currentLine];
		[chars appendString:[NSString stringWithFormat:@"%C", x]];
	}
	
	STAssertEquals((NSUInteger)n, tmpVector.count, @"More than 256 #1.");
	STAssertEquals((NSUInteger)n, chars.length, @"More than 256 #2.");
	[tmpVector insertObject:@"" atIndex:0];
	
	result = diff_linesToCharsForStrings(lines, @"");
	STAssertEqualObjects(chars, [result objectAtIndex:0], @"More than 256 #3.");
	STAssertEqualObjects(@"", [result objectAtIndex:1], @"More than 256 #4.");
	STAssertEqualObjects(tmpVector, (NSArray *)[result objectAtIndex:2], @"More than 256 #5.");
}


- (void)test_diffingToDeltas
{
	// Todo.. add some more exciting text
	NSString *textA = @"Some initial text";
	NSString *textB = @"Some different text";
	NSString *expectedDelta = @"=5	+different	-7	=5";
	
	NSArray *diffs = diff_diffsBetweenTexts(textA, textB);
	STAssertNotNil(diffs, @"!diffs");
	
	NSString *resultingDelta = diff_deltaFromDiffs(diffs);
	STAssertEqualObjects(resultingDelta, expectedDelta, @"resultingDelta != expectedDelta");
}


@end
