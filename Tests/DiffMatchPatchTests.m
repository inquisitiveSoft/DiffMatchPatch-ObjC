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
#import "DMDiff.h"
#import "DMPatch.h"



// Test Utility Function
NSArray *diff_rebuildTextsFromDiffs(NSArray *diffs);



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
	STAssertNil((__bridge_transfer NSArray *)diff_halfMatchCreate((__bridge CFStringRef)@"1234567890", (__bridge CFStringRef)@"abcdef"), @"No match #1.");
	
	STAssertNil((__bridge_transfer NSArray *)diff_halfMatchCreate((__bridge CFStringRef)@"12345", (__bridge CFStringRef)@"23"), @"No match #2.");
	
	// Single Match.
	NSArray *expectedResult = @[@"12", @"90", @"a", @"z", @"345678"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchCreate((__bridge CFStringRef)@"1234567890", (__bridge CFStringRef)@"a345678z"), @"Single Match #1.");
	
	expectedResult = @[@"a", @"z", @"12", @"90", @"345678"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchCreate((__bridge CFStringRef)@"a345678z", (__bridge CFStringRef)@"1234567890"), @"Single Match #2.");
	
	expectedResult = @[@"abc", @"z", @"1234", @"0", @"56789"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchCreate((__bridge CFStringRef)@"abc56789z", (__bridge CFStringRef)@"1234567890"), @"Single Match #3.");
	
	expectedResult = @[@"a", @"xyz", @"1", @"7890", @"23456"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchCreate((__bridge CFStringRef)@"a23456xyz", (__bridge CFStringRef)@"1234567890"), @"Single Match #4.");
	
	// Multiple Matches.
	expectedResult = @[@"12123", @"123121", @"a", @"z", @"1234123451234"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchCreate((__bridge CFStringRef)@"121231234123451234123121", (__bridge CFStringRef)@"a1234123451234z"), @"Multiple Matches #1.");
	
	expectedResult = @[@"", @"-=-=-=-=-=", @"x", @"", @"x-=-=-=-=-=-=-="];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchCreate((__bridge CFStringRef)@"x-=-=-=-=-=-=-=-=-=-=-=-=", (__bridge CFStringRef)@"xx-=-=-=-=-=-=-="), @"Multiple Matches #2.");
	
	expectedResult = @[@"-=-=-=-=-=", @"", @"", @"y", @"-=-=-=-=-=-=-=y"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchCreate((__bridge CFStringRef)@"-=-=-=-=-=-=-=-=-=-=-=-=y", (__bridge CFStringRef)@"-=-=-=-=-=-=-=yy"), @"Multiple Matches #3.");
	
	// Non-optimal halfMatch.
	// Optimal diff would be -q+x=H-i+e=lloHe+Hu=llo-Hew+y not -qHillo+x=HelloHe-w+Hulloy
	expectedResult = @[@"qHillo", @"w", @"x", @"Hulloy", @"HelloHe"];
	STAssertEqualObjects(expectedResult, (__bridge_transfer NSArray *)diff_halfMatchCreate((__bridge CFStringRef)@"qHilloHelloHew", (__bridge CFStringRef)@"xHelloHeHulloy"), @"Non-optimal halfmatch.");
	
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


- (void)test_diff_wordsToCharsTest
{
	// I've removed test_diff_wordsToCharsTest in favour of using
	// diff_tokensToCharsForStrings(text1, text2, tokenType)

	// Convert words down to characters.
	NSMutableArray *tmpVector = [NSMutableArray array];  // Array of NSString objects.
	[tmpVector addObject:@""];
	[tmpVector addObject:@"alpha"];
	[tmpVector addObject:@" "];
	[tmpVector addObject:@"beta"];
	[tmpVector addObject:@"\n"];
	
	NSArray *result = diff_tokensToCharsForStrings(@"alpha beta alpha\n", @"beta alpha beta\n", DiffWordTokens);
	STAssertEqualObjects(@"\001\002\003\002\001\004", [result objectAtIndex:0], @"Convert words down to characters #1");
	STAssertEqualObjects(@"\003\002\001\002\003\004", [result objectAtIndex:1], @"Convert words down to characters #2");
	STAssertEqualObjects(tmpVector, (NSArray *)[result objectAtIndex:2], @"Convert words down to characters #3");
	
	[tmpVector removeAllObjects];
	[tmpVector addObject:@""];
	[tmpVector addObject:@"alpha"];
	[tmpVector addObject:@"\r"];
	[tmpVector addObject:@" "];
	[tmpVector addObject:@"beta"];
	[tmpVector addObject:@"\r\n"];
	
	result = diff_tokensToCharsForStrings(@"", @"alpha\r beta\r \r \r\n", DiffWordTokens);
	STAssertEqualObjects(@"", [result objectAtIndex:0], @"Convert words down to characters #4");
	STAssertEqualObjects(@"\001\002\003\004\002\003\002\003\005", [result objectAtIndex:1], @"Convert words down to characters #5");
	STAssertEqualObjects(tmpVector, (NSArray *)[result objectAtIndex:2], @"Convert words down to characters #6");
	
	[tmpVector removeAllObjects];
	[tmpVector addObject:@""];
	[tmpVector addObject:@"a"];
	[tmpVector addObject:@"b"];
	
	result = diff_tokensToCharsForStrings(@"a", @"b", DiffWordTokens);
	STAssertEqualObjects(@"\001", [result objectAtIndex:0], @"Convert words down to characters #7");
	STAssertEqualObjects(@"\002", [result objectAtIndex:1], @"Convert words down to characters #8");
	STAssertEqualObjects(tmpVector, (NSArray *)[result objectAtIndex:2], @"Convert words down to characters #9");
	
	// More than 256 to reveal any 8-bit limitations.
	unichar n = 300;
	[tmpVector removeAllObjects];
	NSMutableString *words = [NSMutableString string];
	NSMutableString *chars = [NSMutableString string];
	
	[words appendString:@" "];
	
	NSString *currentWord;
	unichar i;
	for (unichar x = 1; x < n + 1; x++) {
		i = x + 1;
		currentWord = [NSString stringWithFormat:@"%d ", (int)x];
		[tmpVector addObject:[NSString stringWithFormat:@"%d", (int)x]];
		[words appendString:currentWord];
		[chars appendString:[NSString stringWithFormat:@"%C\001", i]];
	}
	STAssertEquals((NSUInteger)n, tmpVector.count, @"Convert words down to characters #10");
	STAssertEquals((NSUInteger)n, chars.length/2, @"Convert words down to characters #11");
	[tmpVector insertObject:@"" atIndex:0];
	[tmpVector insertObject:@" " atIndex:1];
	[chars insertString:@"\001" atIndex:0];

	result = diff_tokensToCharsForStrings(words, @"", DiffWordTokens);
	
	NSMutableString *charsCmp = [result objectAtIndex:0];
	STAssertEqualObjects(chars, charsCmp, @"Convert words down to characters #12");
	STAssertEqualObjects(@"", [result objectAtIndex:1], @"Convert words down to characters #13");
	STAssertEqualObjects(tmpVector, (NSArray *)[result objectAtIndex:2], @"Convert words down to characters #14");
}


- (void)test_diff_charsToLinesTest {
	
	// Convert chars up to lines.
	NSArray *diffs = @[
		  [DMDiff diffWithOperation:DIFF_EQUAL andText:@"\001\002\001"],
		  [DMDiff diffWithOperation:DIFF_INSERT andText:@"\002\001\002"]
	];
	
	NSMutableArray *tmpVector = [NSMutableArray array]; // Array of NSString objects.
	[tmpVector addObject:@""];
	[tmpVector addObject:@"alpha\n"];
	[tmpVector addObject:@"beta\n"];
	
	diff_charsToLines(&diffs, tmpVector);
	
	
	NSArray *expectedResult = @[
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"alpha\nbeta\nalpha\n"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"beta\nalpha\nbeta\n"]
	];
	
	STAssertEqualObjects(expectedResult, diffs, @"Shared lines.");
	
	// More than 256 to reveal any 8-bit limitations.
	unichar n = 300;
	[tmpVector removeAllObjects];
	NSMutableString *lines = [NSMutableString string];
	NSMutableString *chars = [NSMutableString string];
	NSString *currentLine;
	for (unichar x = 1; x < n + 1; x++) {
		currentLine = [NSString stringWithFormat:@"%d\n", (int)x];
		[tmpVector addObject:currentLine];
		[lines appendString:currentLine];
		[chars appendString:[NSString stringWithFormat:@"%C", x]];
	}
	STAssertEquals((NSUInteger)n, tmpVector.count, @"More than 256 #1.");
	STAssertEquals((NSUInteger)n, chars.length, @"More than 256 #2.");
	[tmpVector insertObject:@"" atIndex:0];
	
	diffs = @[[DMDiff diffWithOperation:DIFF_DELETE andText:chars]];
	
	diff_charsToLines(&diffs, tmpVector);
	
	STAssertEqualObjects(@[[DMDiff diffWithOperation:DIFF_DELETE andText:lines]], diffs, @"More than 256 #3.");
}


- (void)test_diff_cleanupMergeTest
{
	// Cleanup a messy diff.
	
	// Null case.
	NSMutableArray *expectedResult = nil;
	NSMutableArray *diffs = [NSMutableArray array];
	diff_cleanupMerge(&diffs);
	STAssertEqualObjects([NSMutableArray array], diffs, @"Null case.");
	
	// No change case.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"b"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"c"],
			 nil];
	
	diff_cleanupMerge(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"b"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"c"],
			nil];
	
	NSLog(@"diffs: %@", diffs);
	NSLog(@"expectedResult: %@", expectedResult);
	STAssertEqualObjects(expectedResult, diffs, @"No change case.");
	
	// Merge equalities.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"b"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"c"],
			nil];
	
	diff_cleanupMerge(&diffs);
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"abc"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Merge equalities.");
	
	
	// Merge deletions.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"a"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"b"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"c"],
			nil];
	
	diff_cleanupMerge(&diffs);
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abc"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Merge deletions.");
	
	
	// Merge insertions.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"a"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"b"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"c"],
			nil];
	
	diff_cleanupMerge(&diffs);
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"abc"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Merge insertions.");
	
	
	// Merge interweave.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"a"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"b"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"c"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"d"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"e"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"f"],
			nil];
	
	diff_cleanupMerge(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"ac"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"bd"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"ef"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Merge interweave.");
	
	// Prefix and suffix detection.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"a"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"abc"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"dc"], nil];
	
	diff_cleanupMerge(&diffs);
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"d"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"b"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"c"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Prefix and suffix detection.");
	
	// Prefix and suffix detection with equalities.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"x"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"a"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"abc"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"dc"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"y"],
			nil];
	
	diff_cleanupMerge(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:[DMDiff diffWithOperation:DIFF_EQUAL andText:@"xa"], [DMDiff diffWithOperation:DIFF_DELETE andText:@"d"], [DMDiff diffWithOperation:DIFF_INSERT andText:@"b"], [DMDiff diffWithOperation:DIFF_EQUAL andText:@"cy"], nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Prefix and suffix detection with equalities.");
	
			
    // Slide edit left.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"ba"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"c"],
			nil];
	
	diff_cleanupMerge(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"ab"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"ac"],
			nil];
		
	STAssertEqualObjects(expectedResult, diffs, @"Slide edit left.");
	
	
	// Slide edit right.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"c"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"ab"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
			 nil];
	
	diff_cleanupMerge(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"ca"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"ba"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Slide edit right.");
	
	
	// Slide edit left recursive.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"b"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"c"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"ac"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"x"],
			nil];
	
	diff_cleanupMerge(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abc"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"acx"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Slide edit left recursive.");
	
	
	// Slide edit right recursive.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"x"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"ca"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"c"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"b"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
			nil];
	
	diff_cleanupMerge(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"xca"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"cba"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Slide edit right recursive.");
}


- (void)test_diff_cleanupSemanticLosslessTest
{
	// Slide diffs to match logical boundaries.
	
	
	// Null case.
	NSMutableArray *diffs = [NSMutableArray array];
	diff_cleanupSemanticLossless(&diffs);
	STAssertEqualObjects([NSMutableArray array], diffs, @"Null case.");
	
	
	// Blank lines.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"AAA\r\n\r\nBBB"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"\r\nDDD\r\n\r\nBBB"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"\r\nEEE"],
			nil];
	
	diff_cleanupSemanticLossless(&diffs);
	
	
	NSMutableArray *expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"AAA\r\n\r\n"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"BBB\r\nDDD\r\n\r\n"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"BBB\r\nEEE"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Blank lines.");
	
	
	// Line boundaries.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"AAA\r\nBBB"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@" DDD\r\nBBB"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@" EEE"],
			nil];
	
	diff_cleanupSemanticLossless(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"AAA\r\n"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"BBB DDD\r\n"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"BBB EEE"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Line boundaries.");
	
	
	// Word boundaries.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"The c"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"ow and the c"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"at."],
			nil];
	
	diff_cleanupSemanticLossless(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"The "],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"cow and the "],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"cat."],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Word boundaries.");
	
	
	// Alphanumeric boundaries.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"The-c"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"ow-and-the-c"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"at."],
			nil];
	
	diff_cleanupSemanticLossless(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"The-"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"cow-and-the-"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"cat."],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Alphanumeric boundaries.");
	
	
	// Hitting the start.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"a"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"ax"],
			nil];
	
	diff_cleanupSemanticLossless(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"a"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"aax"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Hitting the start.");
	
	
	// Hitting the end.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"xa"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"a"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
			nil];
	
	diff_cleanupSemanticLossless(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"xaa"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"a"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Hitting the end.");
	
	
	// Alphanumeric boundaries.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"The xxx. The "],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"zzz. The "],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"yyy."],
			nil];
	
	diff_cleanupSemanticLossless(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"The xxx."],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@" The zzz."],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@" The yyy."],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Sentence boundaries.");
}


- (void)test_diff_cleanupSemanticTest
{
	// Cleanup semantically trivial equalities.
	
	// Null case.
	NSMutableArray *diffs = [NSMutableArray array];
	diff_cleanupSemantic(&diffs);
	STAssertEqualObjects([NSMutableArray array], diffs, @"Null case.");
	
	
	// No elimination #1.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"ab"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"cd"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"12"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"e"],
			nil];
	
	diff_cleanupSemantic(&diffs);
	NSMutableArray *expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"ab"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"cd"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"12"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"e"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"No elimination #1.");
	
	
	// No elimination #2.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abc"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"ABC"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"1234"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"wxyz"],
			nil];
	
	diff_cleanupSemantic(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abc"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"ABC"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"1234"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"wxyz"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"No elimination #2.");
	
	
	// Simple elimination.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"a"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"b"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"c"],
			nil];
	
	diff_cleanupSemantic(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abc"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"b"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Simple elimination.");
	
	
	// Backpass elimination.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"ab"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"cd"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"e"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"f"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"g"],
			nil];
	
	diff_cleanupSemantic(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abcdef"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"cdfg"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Backpass elimination.");
	
	
	// Multiple eliminations.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"1"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"A"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"B"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"2"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"_"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"1"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"A"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"B"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"2"],
			nil];
	
	diff_cleanupSemantic(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"AB_AB"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"1A2_1A2"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Multiple eliminations.");
	
	
	// Word boundaries.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"The c"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"ow and the c"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"at."],
			nil];
	
	diff_cleanupSemantic(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"The "],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"cow and the "],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"cat."],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Word boundaries.");
	
	
	// No overlap elimination.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abcxx"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"xxdef"],
			nil];
	
	diff_cleanupSemantic(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abcxx"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"xxdef"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"No overlap elimination.");
	
	
	// Overlap elimination.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abcxxx"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"xxxdef"],
			nil];
	
	diff_cleanupSemantic(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abc"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"xxx"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"def"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Overlap elimination.");
	
	
	// Reverse overlap elimination.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"xxxabc"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"defxxx"],
			nil];
	
	diff_cleanupSemantic(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"def"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"xxx"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abc"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Reverse overlap elimination.");
	
	
	// Two overlap eliminations.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abcd1212"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"1212efghi"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"----"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"A3"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"3BC"],
			nil];
	
	diff_cleanupSemantic(&diffs);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abcd"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"1212"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"efghi"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"----"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"A"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"3"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"BC"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Two overlap eliminations.");
}


- (void)test_diff_cleanupEfficiencyTest
{
	// Cleanup operationally trivial equalities.
	PatchProperties properties = patch_defaultPatchProperties();
	properties.diffEditingCost = 4;
	
	// Null case.
	NSMutableArray *diffs = [NSMutableArray array];
	patch_cleanupDiffsForEfficiency(&diffs, properties);
	STAssertEqualObjects([NSMutableArray array], diffs, @"Null case.");
	
	// No elimination.
	diffs = [NSMutableArray arrayWithObjects:
			 [DMDiff diffWithOperation:DIFF_DELETE andText:@"ab"],
			 [DMDiff diffWithOperation:DIFF_INSERT andText:@"12"],
			 [DMDiff diffWithOperation:DIFF_EQUAL andText:@"wxyz"],
			 [DMDiff diffWithOperation:DIFF_DELETE andText:@"cd"],
			 [DMDiff diffWithOperation:DIFF_INSERT andText:@"34"], nil];
	
	patch_cleanupDiffsForEfficiency(&diffs, properties);
	
	NSMutableArray *expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"ab"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"12"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"wxyz"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"cd"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"34"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"No elimination.");
	
	// Four-edit elimination.
	diffs = [NSMutableArray arrayWithObjects:
			 [DMDiff diffWithOperation:DIFF_DELETE andText:@"ab"],
			 [DMDiff diffWithOperation:DIFF_INSERT andText:@"12"],
			 [DMDiff diffWithOperation:DIFF_EQUAL andText:@"xyz"],
			 [DMDiff diffWithOperation:DIFF_DELETE andText:@"cd"],
			 [DMDiff diffWithOperation:DIFF_INSERT andText:@"34"], nil];
	
	patch_cleanupDiffsForEfficiency(&diffs, properties);
	expectedResult = [NSMutableArray arrayWithObjects:
					  [DMDiff diffWithOperation:DIFF_DELETE andText:@"abxyzcd"],
					  [DMDiff diffWithOperation:DIFF_INSERT andText:@"12xyz34"], nil];
	STAssertEqualObjects(expectedResult, diffs, @"Four-edit elimination.");
	
	// Three-edit elimination.
	diffs = [NSMutableArray arrayWithObjects:
			 [DMDiff diffWithOperation:DIFF_INSERT andText:@"12"],
			 [DMDiff diffWithOperation:DIFF_EQUAL andText:@"x"],
			 [DMDiff diffWithOperation:DIFF_DELETE andText:@"cd"],
			 [DMDiff diffWithOperation:DIFF_INSERT andText:@"34"], nil];
	patch_cleanupDiffsForEfficiency(&diffs, properties);
	expectedResult = [NSMutableArray arrayWithObjects:
					  [DMDiff diffWithOperation:DIFF_DELETE andText:@"xcd"],
					  [DMDiff diffWithOperation:DIFF_INSERT andText:@"12x34"], nil];
	STAssertEqualObjects(expectedResult, diffs, @"Three-edit elimination.");
	
	// Backpass elimination.
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"ab"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"12"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"xy"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"34"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"z"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"cd"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"56"],
			nil];
	
	patch_cleanupDiffsForEfficiency(&diffs, properties);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abxyzcd"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"12xy34z56"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"Backpass elimination.");
	
	
	// High cost elimination.
	properties.diffEditingCost = 5;
	
	diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"ab"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"12"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"wxyz"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"cd"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"34"],
			nil];
	
	patch_cleanupDiffsForEfficiency(&diffs, properties);
	
	expectedResult = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abwxyzcd"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"12wxyz34"],
			nil];
	
	STAssertEqualObjects(expectedResult, diffs, @"High cost elimination.");
}



- (void)test_diff_prettyHtmlTest
{
	// Pretty print.
	NSMutableArray *diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a\n"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"<B>b</B>"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"c&d"],
			nil];
	
	NSString *expectedResult = @"<span>a&para;<br></span><del style=\"background:#ffe6e6;\">&lt;B&gt;b&lt;/B&gt;</del><ins style=\"background:#e6ffe6;\">c&amp;d</ins>";
	STAssertEqualObjects(expectedResult, diff_prettyHTMLFromDiffs(diffs), @"Pretty print.");
}


- (void)test_diff_textTest {
	// Compute the source and destination texts.
	NSMutableArray *diffs = [NSMutableArray arrayWithObjects:
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"jump"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"s"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"ed"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@" over "],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"the"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"a"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@" lazy"],
			nil];
	
	STAssertEqualObjects(@"jumps over the lazy", diff_text1(diffs), @"Compute the source and destination texts #1");
	STAssertEqualObjects(@"jumped over a lazy", diff_text2(diffs), @"Compute the source and destination texts #2");
}


- (void)test_diff_deltaTest
{
	// Convert a diff into delta string.
	NSArray *diffs = @[
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"jump"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"s"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"ed"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@" over "],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"the"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"a"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@" lazy"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"old dog"],
			];
	
	NSString *text1 = diff_text1(diffs);
	STAssertEqualObjects(@"jumps over the lazy", text1, @"Convert a diff into delta string 1.");
	
	NSString *delta = diff_deltaFromDiffs(diffs);
	STAssertEqualObjects(@"=4\t-1\t+ed\t=6\t-3\t+a\t=5\t+old dog", delta, @"Convert a diff into delta string 2.");
	
	// Convert delta string into a diff.
	STAssertEqualObjects(diffs, diff_diffsFromOriginalTextAndDelta(text1, delta, NULL), @"Convert delta string into a diff.");
	
	// Generates error (19 < 20).
	NSError *error = nil;
	diffs = diff_diffsFromOriginalTextAndDelta([text1 stringByAppendingString:@"x"], delta, &error);
	if(diffs != nil || error == nil)
		STFail(@"diff_fromDelta: Too long.");
	
	// Generates error (19 > 18).
	error = nil;
	diffs = diff_diffsFromOriginalTextAndDelta([text1 substringFromIndex:1], delta, &error);
	if(diffs != nil || error == nil)
		STFail(@"diff_fromDelta: Too short.");
	
	// Generates error (%c3%xy invalid Unicode).
	error = nil;
	diffs = diff_diffsFromOriginalTextAndDelta(@"", @"+%c3%xy", &error);
	if(diffs != nil || error == nil)
		STFail(@"diff_fromDelta: Invalid character.");
	
	// Test deltas with special characters.
	unichar zero = (unichar)0;
	unichar one = (unichar)1;
	unichar two = (unichar)2;
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_EQUAL andText:[NSString stringWithFormat:@"\U00000680 %C \t %%", zero]],
		[DMDiff diffWithOperation:DIFF_DELETE andText:[NSString stringWithFormat:@"\U00000681 %C \n ^", one]],
		[DMDiff diffWithOperation:DIFF_INSERT andText:[NSString stringWithFormat:@"\U00000682 %C \\ |", two]],
	];
	
	text1 = diff_text1(diffs);
	
	NSString *expectedString = [NSString stringWithFormat:@"\U00000680 %C \t %%\U00000681 %C \n ^", zero, one];
	STAssertEqualObjects(expectedString, text1, @"Test deltas with special characters.");
	
	delta = diff_deltaFromDiffs(diffs);
	
	// Upper case, because to CFURLCreateStringByAddingPercentEscapes() uses upper.
	STAssertEqualObjects(@"=7\t-7\t+%DA%82 %02 %5C %7C", delta, @"diff_toDelta: Unicode 1.");
	
	STAssertEqualObjects(diffs, diff_diffsFromOriginalTextAndDelta(text1, delta, NULL), @"diff_fromDelta: Unicode 2.");
	
	// Verify pool of unchanged characters.
	NSArray *expectedResult = @[[DMDiff diffWithOperation:DIFF_INSERT andText:@"A-Z a-z 0-9 - _ . ! ~ * ' ( ) ; / ? : @ & = + $ , # "]];
	
	NSString *text2 = diff_text2(expectedResult);
	STAssertEqualObjects(@"A-Z a-z 0-9 - _ . ! ~ * ' ( ) ; / ? : @ & = + $ , # ", text2, @"diff_text2: Unchanged characters 1.");
	
	delta = diff_deltaFromDiffs(expectedResult);
	STAssertEqualObjects(@"+A-Z a-z 0-9 - _ . ! ~ * ' ( ) ; / ? : @ & = + $ , # ", delta, @"diff_toDelta: Unchanged characters 2.");
	
	// Convert delta string into a diff.
	diffs = diff_diffsFromOriginalTextAndDelta(@"", delta, NULL);
	STAssertEqualObjects(diffs, expectedResult, @"diff_fromDelta: Unchanged characters. Convert delta string into a diff.");
}


- (void)test_diff_translateLocationFromText1ToText2
{
	// Translate a location in text1 to text2.
	NSArray *diffs = @[
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"a"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"1234"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"xyz"],
	];
	
	STAssertEquals((NSUInteger)5, diff_translateLocationFromText1ToText2(diffs, 2), @"diff_translateLocationFromText1ToText2: Translation on equality. Translate a location in text1 to text2.");
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"1234"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"xyz"]
	];
	
	STAssertEquals((NSUInteger)1, diff_translateLocationFromText1ToText2(diffs, 3), @"diff_translateLocationFromText1ToText2: Translation on deletion.");
}


- (void)test_diff_levenshteinTest
{
	NSArray *diffs = @[
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abc"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"1234"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"xyz"]
	];
	
	STAssertEquals((NSUInteger)4, diff_levenshtein(diffs), @"diff_levenshtein: Levenshtein with trailing equality.");
	
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"xyz"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abc"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"1234"]
	];
	
	STAssertEquals((NSUInteger)4, diff_levenshtein(diffs), @"diff_levenshtein: Levenshtein with leading equality.");
	
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"abc"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"xyz"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"1234"]
	];
	
	STAssertEquals((NSUInteger)7, diff_levenshtein(diffs), @"diff_levenshtein: Levenshtein with middle equality.");
}


- (void)diff_bisectTest;
{
	// Normal.
	NSString *a = @"cat";
	NSString *b = @"map";
	DiffProperties properties = diff_defaultDiffProperties();
	
	// Since the resulting diff hasn't been normalized, it would be ok if
	// the insertion and deletion pairs are swapped.
	// If the order changes, tweak this test as required.
	NSArray *diffs = @[
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"c"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"m"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"t"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"p"]
	];
	
	properties.deadline = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
	STAssertEqualObjects(diffs, diff_bisectOfStrings(a, b, properties), @"Bisect test.");
	
	// Timeout.
	diffs = @[
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"cat"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"map"]
	];
	
	properties.deadline = [[NSDate distantPast] timeIntervalSinceReferenceDate];
	STAssertEqualObjects(diffs, diff_bisectOfStrings(a, b, properties), @"Bisect timeout.");
}



- (void)test_diff_mainTest
{
	// Perform a trivial diff.
	NSArray *diffs = @[];
	STAssertEqualObjects(diffs, diff_diffsBetweenTexts(@"", @""), @"diff_main: Null case.");
	
	
	diffs = @[[DMDiff diffWithOperation:DIFF_EQUAL andText:@"abc"]];
	STAssertEqualObjects(diffs, diff_diffsBetweenTexts(@"abc", @"abc"), @"diff_main: Equality.");
	
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"ab"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"123"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"c"]
	];
	STAssertEqualObjects(diffs, diff_diffsBetweenTexts(@"abc", @"ab123c"), @"diff_main: Simple insertion.");
	
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"123"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"bc"],
	];
	STAssertEqualObjects(diffs, diff_diffsBetweenTexts(@"a123bc", @"abc"), @"diff_main: Simple deletion.");
	
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"123"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"b"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"456"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"c"],
	];
	STAssertEqualObjects(diffs, diff_diffsBetweenTexts(@"abc", @"a123b456c"), @"diff_main: Two insertions.");
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"123"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"b"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"456"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"c"]
	];
	STAssertEqualObjects(diffs, diff_diffsBetweenTexts(@"a123b456c", @"abc"), @"diff_main: Two deletions.");
	
	// Perform a real diff.
	// Switch off the timeout.
	diffs = @[
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"a"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"b"]
	];
	STAssertEqualObjects(diffs, diff_diffsBetweenTextsWithOptions(@"a", @"b", TRUE, 0.0), @"diff_main: Simple case #1.");
	
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"Apple"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"Banana"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"s are a"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"lso"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@" fruit."]
	];
	diff_diffsBetweenTextsWithOptions(@"Apples are a fruit.", @"Bananas are also fruit.", TRUE, 0.0);
	
	STAssertEqualObjects(diffs, diff_diffsBetweenTextsWithOptions(@"Apples are a fruit.", @"Bananas are also fruit.", TRUE, 0.0), @"diff_main: Simple case #2.");
	
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"a"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"\U00000680"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"x"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"\t"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:[NSString stringWithFormat:@"%C", (unichar)0]]
	];
	STAssertEqualObjects(diffs, diff_diffsBetweenTextsWithOptions(@"ax\t", [NSString stringWithFormat:@"\U00000680x%C", (unichar)0], TRUE, 0.0), @"diff_main: Simple case #3.");
	
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"1"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"y"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"b"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"2"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"xab"]
	];
	STAssertEqualObjects(diffs, diff_diffsBetweenTextsWithOptions(@"1ayb2", @"abxab", TRUE, 0.0), @"diff_main: Overlap #1.");
	
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"xaxcx"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"abc"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"y"]
	];
	STAssertEqualObjects(diffs, diff_diffsBetweenTextsWithOptions(@"abcy", @"xaxcxabc", TRUE, 0.0), @"diff_main: Overlap #2.");
	
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"ABCD"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"="],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"-"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"bcd"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"="],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"-"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"efghijklmnopqrs"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@"EFGHIJKLMNOefg"]
	];
	STAssertEqualObjects(diffs, diff_diffsBetweenTextsWithOptions(@"ABCDa=bcd=efghijklmnopqrsEFGHIJKLMNOefg", @"a-bcd-efghijklmnopqrs", TRUE, 0.0), @"diff_main: Overlap #3.");
	
	
	diffs = @[
		[DMDiff diffWithOperation:DIFF_INSERT andText:@" "],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@"a"],
		[DMDiff diffWithOperation:DIFF_INSERT andText:@"nd"],
		[DMDiff diffWithOperation:DIFF_EQUAL andText:@" [[Pennsylvania]]"],
		[DMDiff diffWithOperation:DIFF_DELETE andText:@" and [[New"]
	];
	STAssertEqualObjects(diffs, diff_diffsBetweenTextsWithOptions(@"a [[Pennsylvania]] and [[New", @" and [[Pennsylvania]]", TRUE, 0.0), @"diff_main: Large equality.");
	

//	dmp.Diff_Timeout = 0.1f;  // 100ms
	NSString *a = @"`Twas brillig, and the slithy toves\nDid gyre and gimble in the wabe:\nAll mimsy were the borogoves,\nAnd the mome raths outgrabe.\n";
	NSString *b = @"I am the very model of a modern major general,\nI've information vegetable, animal, and mineral,\nI know the kings of England, and I quote the fights historical,\nFrom Marathon to Waterloo, in order categorical.\n";
	NSMutableString *aMutable = [NSMutableString stringWithString:a];
	NSMutableString *bMutable = [NSMutableString stringWithString:b];
	// Increase the text lengths by 1024 times to ensure a timeout.
	for (int x = 0; x < 10; x++) {
		[aMutable appendString:aMutable];
		[bMutable appendString:bMutable];
	}
	a = aMutable;
	b = bMutable;
	
	NSTimeInterval timeLimit = 0.1f;
	NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
	diff_diffsBetweenTextsWithOptions(a, b, TRUE, timeLimit);
	NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate];
	
	// Test that we took at least the timeout period.
	STAssertTrue((timeLimit <= (endTime - startTime)), @"Test that we took at least the timeout period.");
	// Test that we didn't take forever (be forgiving).
	// Theoretically this test could fail very occasionally if the
	// OS task swaps or locks up for a second at the wrong moment.
	// This will fail when running this as PPC code thru Rosetta on Intel.
	STAssertTrue(((timeLimit * 2) > (endTime - startTime)), @"Test that we didn't take forever (be forgiving).");
	
	
	// Test the linemode speedup.
	// Must be long to pass the 200 character cutoff.
	a = @"1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n";
	b = @"abcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\n";
		
	STAssertEqualObjects(diff_diffsBetweenTextsWithOptions(a, b, FALSE, 0.0), diff_diffsBetweenTextsWithOptions(a, b, TRUE, 0.0), @"diff_main: Simple line-mode.");
	
	a = @"1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890";
	b = @"abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij";
	STAssertEqualObjects(diff_diffsBetweenTextsWithOptions(a, b, FALSE, 0.0), diff_diffsBetweenTextsWithOptions(a, b, TRUE, 0.0), @"diff_main: Single line-mode.");
	
	a = @"1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n";
	b = @"abcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n";
	
	NSArray *texts_linemode = diff_rebuildTextsFromDiffs(diff_diffsBetweenTextsWithOptions(a, b, FALSE, 0.0));
	NSArray *texts_textmode = diff_rebuildTextsFromDiffs(diff_diffsBetweenTextsWithOptions(a, b, TRUE, 0.0));;
	STAssertEqualObjects(texts_textmode, texts_linemode, @"diff_main: Overlap line-mode.");
	
	
	// Test null inputs
	STAssertNil(diff_diffsBetweenTexts(NULL, NULL), @"Test null inputs. #1");
	STAssertNil(diff_diffsBetweenTexts(@"a", NULL), @"Test null inputs. #2");
	STAssertNil(diff_diffsBetweenTexts(NULL, @"b"), @"Test null inputs. #3");
}



#pragma mark Match Test Functions


- (void)test_match_alphabetTest {
	// Initialise the bitmasks for Bitap.
	NSMutableDictionary *bitmask = [@{ @"a" : @(4), @"b" : @(2), @"c" : @(1) } mutableCopy];
	STAssertEqualObjects(bitmask, match_alphabetFromPattern(@"abc"), @"match_alphabet: Unique.");
	
	bitmask = [@{ @"a" : @(37), @"b" : @(18), @"c" : @(8) } mutableCopy];
	STAssertEqualObjects(bitmask, match_alphabetFromPattern(@"abcaba"), @"match_alphabet: Duplicates.");
}


- (void)test_match_bitapTest
{
	// Bitap algorithm.
	MatchProperties properties = match_defaultMatchProperties();
	properties.matchDistance = 100;
	properties.matchThreshold = 0.5f;
	
	STAssertEquals((NSUInteger)5, match_bitapOfTextAndPattern(@"abcdefghijk", @"fgh", 5, properties), @"match_bitap: Exact match #1.");
	STAssertEquals((NSUInteger)5, match_bitapOfTextAndPattern(@"abcdefghijk", @"fgh", 5, properties), @"match_bitap: Exact match #2.");
	STAssertEquals((NSUInteger)4, match_bitapOfTextAndPattern(@"abcdefghijk", @"efxhi", 0, properties), @"match_bitap: Fuzzy match #1.");
	STAssertEquals((NSUInteger)2, match_bitapOfTextAndPattern(@"abcdefghijk", @"cdefxyhijk", 5, properties), @"match_bitap: Fuzzy match #2.");
	STAssertEquals((NSUInteger)NSNotFound, match_bitapOfTextAndPattern(@"abcdefghijk", @"bxy", 1, properties), @"match_bitap: Fuzzy match #3.");
	STAssertEquals((NSUInteger)2, match_bitapOfTextAndPattern(@"123456789xx0", @"3456789x0", 2, properties), @"match_bitap: Overflow.");
	STAssertEquals((NSUInteger)0, match_bitapOfTextAndPattern(@"abcdef", @"xxabc", 4, properties), @"match_bitap: Before start match.");
	STAssertEquals((NSUInteger)3, match_bitapOfTextAndPattern(@"abcdef", @"defyy", 4, properties), @"match_bitap: Beyond end match.");
	STAssertEquals((NSUInteger)0, match_bitapOfTextAndPattern(@"abcdef", @"xabcdefy", 0, properties), @"match_bitap: Oversized pattern.");
	
	properties.matchThreshold = 0.4f;
	STAssertEquals((NSUInteger)4, match_bitapOfTextAndPattern(@"abcdefghijk", @"efxyhi", 1, properties), @"match_bitap: Threshold #1.");
	
	properties.matchThreshold = 0.3f;
	STAssertEquals((NSUInteger)NSNotFound, match_bitapOfTextAndPattern(@"abcdefghijk", @"efxyhi", 1, properties), @"match_bitap: Threshold #2.");

	properties.matchThreshold = 0.0f;
	STAssertEquals((NSUInteger)1, match_bitapOfTextAndPattern(@"abcdefghijk", @"bcdef", 1, properties), @"match_bitap: Threshold #3.");
	
	properties.matchThreshold = 0.5f;
	STAssertEquals((NSUInteger)0, match_bitapOfTextAndPattern(@"abcdexyzabcde", @"abccde", 3, properties), @"match_bitap: Multiple select #1.");
	STAssertEquals((NSUInteger)8, match_bitapOfTextAndPattern(@"abcdexyzabcde", @"abccde", 5, properties), @"match_bitap: Multiple select #2.");
	
	properties.matchDistance = 10;  // Strict location.
	STAssertEquals((NSUInteger)NSNotFound, match_bitapOfTextAndPattern(@"abcdefghijklmnopqrstuvwxyz", @"abcdefg", 24, properties), @"match_bitap: Distance test #1.");
	STAssertEquals((NSUInteger)0, match_bitapOfTextAndPattern(@"abcdefghijklmnopqrstuvwxyz", @"abcdxxefg", 1, properties), @"match_bitap: Distance test #2.");
	
	properties.matchDistance = 1000;  // Loose location.
	STAssertEquals((NSUInteger)0, match_bitapOfTextAndPattern(@"abcdefghijklmnopqrstuvwxyz", @"abcdefg", 24, properties), @"match_bitap: Distance test #3.");
}



- (void)test_match_mainTest
{	
	// Full match.
	STAssertEquals((NSUInteger)0, match_locationOfMatchInText(@"abcdef", @"abcdef", 1000), @"match_main: Equality.");
	STAssertEquals((NSUInteger)NSNotFound, match_locationOfMatchInText(@"", @"abcdef", 1), @"match_main: Null text.");
	STAssertEquals((NSUInteger)3, match_locationOfMatchInText(@"abcdef", @"", 3), @"match_main: Null pattern.");
	STAssertEquals((NSUInteger)3, match_locationOfMatchInText(@"abcdef", @"de", 3), @"match_main: Exact match.");
	STAssertEquals((NSUInteger)3, match_locationOfMatchInText(@"abcdef", @"defy", 4), @"match_main: Beyond end match.");
	STAssertEquals((NSUInteger)0, match_locationOfMatchInText(@"abcdef", @"abcdefy", 0), @"match_main: Oversized pattern.");
	STAssertEquals((NSUInteger)4, match_locationOfMatchInTextWithOptions(@"I am the very model of a modern major general.", @" that berry ", 5, 0.7f, 1000), @"match_main: Complex match.");
	
	STAssertEquals((NSUInteger)NSNotFound, match_locationOfMatchInText(NULL, @"Pattern", 0), @"match_main: Null text.");
	STAssertEquals((NSUInteger)NSNotFound, match_locationOfMatchInText(@"Text", NULL, 0), @"match_main: Null pattern.");
	STAssertEquals((NSUInteger)NSNotFound, match_locationOfMatchInText(NULL, NULL, 0), @"match_main: Both null.");
}


#pragma mark Patch Test Functions
//  PATCH TEST FUNCTIONS


- (void)test_patch_patchObjTest {
	// Patch Object.
	DMPatch *patch = [[DMPatch alloc] init];
	patch.start1 = 20;
	patch.start2 = 21;
	patch.length1 = 18;
	patch.length2 = 17;
	patch.diffs = [NSMutableArray arrayWithObjects:
	   [DMDiff diffWithOperation:DIFF_EQUAL andText:@"jump"],
	   [DMDiff diffWithOperation:DIFF_DELETE andText:@"s"],
	   [DMDiff diffWithOperation:DIFF_INSERT andText:@"ed"],
	   [DMDiff diffWithOperation:DIFF_EQUAL andText:@" over "],
	   [DMDiff diffWithOperation:DIFF_DELETE andText:@"the"],
	   [DMDiff diffWithOperation:DIFF_INSERT andText:@"a"],
	   [DMDiff diffWithOperation:DIFF_EQUAL andText:@"\nlaz"],
		   nil];
	
	NSString *expectedDescription = @"@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n %0Alaz\n";
	STAssertEqualObjects(expectedDescription, [patch patchText], @"Patch: description.");
}


- (void)test_patch_fromTextTest
{
	
	STAssertTrue(patch_parsePatchesFromText(@"", NULL).count == 0, @"patch_fromText: #0.");
	
	NSString *patchesAsText = @"@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n %0Alaz\n";
	STAssertEqualObjects(patchesAsText, [[patch_parsePatchesFromText(patchesAsText, NULL) objectAtIndex:0] patchText], @"patch_fromText: #1.");
	
	patchesAsText = @"@@ -1 +1 @@\n-a\n+b\n";
	STAssertEqualObjects(patchesAsText, [[patch_parsePatchesFromText(patchesAsText, NULL) objectAtIndex:0] patchText], @"patch_fromText: #2.");
	
	patchesAsText = @"@@ -1,3 +0,0 @@\n-abc\n";
	STAssertEqualObjects(patchesAsText, [[patch_parsePatchesFromText(patchesAsText, NULL) objectAtIndex:0] patchText], @"patch_fromText: #3.");
	
	patchesAsText = @"@@ -0,0 +1,3 @@\n+abc\n";
	STAssertEqualObjects(patchesAsText, [[patch_parsePatchesFromText(patchesAsText, NULL) objectAtIndex:0] patchText], @"patch_fromText: #4.");
	
	// Generates error.
	NSError *error = nil;
	NSArray *patches = patch_parsePatchesFromText(@"Bad\nPatch\n", &error);
	
	if(patches != nil || error == nil) {
		// Error expected.
		STFail(@"patch_fromText: #5.");
	}
}


- (void)test_patch_toTextTest
{
	NSString *patchesAsText = @"@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n  laz\n";
	NSArray *patches = patch_parsePatchesFromText(patchesAsText, NULL);
	STAssertEqualObjects(patchesAsText, patch_patchesToText(patches), @"toText Test #1");
	
	patchesAsText = @"@@ -1,9 +1,9 @@\n-f\n+F\n oo+fooba\n@@ -7,9 +7,9 @@\n obar\n-,\n+.\n  tes\n";
	patches = patch_parsePatchesFromText(patchesAsText, NULL);
	STAssertEqualObjects(patchesAsText, patch_patchesToText(patches), @"toText Test #2");
}


- (void)test_patch_addContextTest
{
	PatchProperties properties = patch_defaultPatchProperties();
	properties.patchMargin = 4;

	DMPatch *patch = [patch_parsePatchesFromText(@"@@ -21,4 +21,10 @@\n-jump\n+somersault\n", NULL) objectAtIndex:0];
	[patch addContext:@"The quick brown fox jumps over the lazy dog." withMargin:properties.patchMargin maximumBits:properties.matchProperties.matchMaximumBits];
	STAssertEqualObjects(@"@@ -17,12 +17,18 @@\n fox \n-jump\n+somersault\n s ov\n", [patch patchText], @"patch_addContext: Simple case.");
	
	patch = [patch_parsePatchesFromText(@"@@ -21,4 +21,10 @@\n-jump\n+somersault\n", NULL) objectAtIndex:0];
	[patch addContext:@"The quick brown fox jumps." withMargin:properties.patchMargin maximumBits:properties.matchProperties.matchMaximumBits];
	STAssertEqualObjects(@"@@ -17,10 +17,16 @@\n fox \n-jump\n+somersault\n s.\n", [patch patchText], @"patch_addContext: Not enough trailing context.");
	
	patch = [patch_parsePatchesFromText(@"@@ -3 +3,2 @@\n-e\n+at\n", NULL) objectAtIndex:0];
	[patch addContext:@"The quick brown fox jumps." withMargin:properties.patchMargin maximumBits:properties.matchProperties.matchMaximumBits];
	STAssertEqualObjects(@"@@ -1,7 +1,8 @@\n Th\n-e\n+at\n  qui\n", [patch patchText], @"patch_addContext: Not enough leading context.");
	
	
	patch = [patch_parsePatchesFromText(@"@@ -3 +3,2 @@\n-e\n+at\n", NULL) objectAtIndex:0];
	[patch addContext:@"The quick brown fox jumps.  The quick brown fox crashes." withMargin:properties.patchMargin maximumBits:properties.matchProperties.matchMaximumBits];
	STAssertEqualObjects(@"@@ -1,27 +1,28 @@\n Th\n-e\n+at\n  quick brown fox jumps. \n", [patch patchText], @"patch_addContext: Ambiguity.");
}


- (void)test_patch_makeTest
{
	NSArray *patches = patch_patchesFromTexts(@"", @"");
	STAssertEqualObjects(@"", patch_patchesToText(patches), @"patch_patchesFromTexts: Empty case.");

	patches = patch_patchesFromTexts(nil, nil);
	STAssertEqualObjects(@"", patch_patchesToText(patches), @"patch_patchesFromTexts: Nil case.");
	
	NSString *text1 = @"The quick brown fox jumps over the lazy dog.";
	NSString *text2 = @"That quick brown fox jumped over a lazy dog.";
	NSString *patchAsText = @"@@ -1,8 +1,7 @@\n Th\n-at\n+e\n  qui\n@@ -21,17 +21,18 @@\n jump\n-ed\n+s\n  over \n-a\n+the\n  laz\n";
	// The second patch must be @"-21,17 +21,18", not @"-22,17 +21,18" due to rolling context.
	
	patches = patch_patchesFromTexts(text2, text1);
	STAssertEqualObjects(patchAsText, patch_patchesToText(patches), @"patch_patchesFromTexts: Text2+Text1 inputs.");
	
	patchAsText = @"@@ -1,11 +1,12 @@\n Th\n-e\n+at\n  quick b\n@@ -22,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n  laz\n";
	patches = patch_patchesFromTexts(text1, text2);
	STAssertEqualObjects(patchAsText, patch_patchesToText(patches), @"patch_patchesFromTexts: Text1+Text2 inputs.");
	
	PatchProperties properties = patch_defaultPatchProperties();
	NSArray *diffs = diff_diffsBetweenTexts(text1, text2);
	patches = patch_patchesFromDiffs(diffs, properties);
	STAssertEqualObjects(patchAsText, patch_patchesToText(patches), @"patch_patchesFromDiffs: Diff input.");
	
	patches = patch_patchesFromTextAndDiffs(text1, diffs, properties);
	STAssertEqualObjects(patchAsText, patch_patchesToText(patches), @"patch_patchesFromTextAndDiffs: Text1+Diff inputs.");
		
	
	patches = patch_patchesFromTexts(@"`1234567890-=[]\\;',./", @"~!@#$%^&*()_+{}|:\"<>?");
	STAssertEqualObjects(@"@@ -1,21 +1,21 @@\n-%601234567890-=%5B%5D%5C;',./\n+~!@#$%25%5E&*()_+%7B%7D%7C:%22%3C%3E?\n", patch_patchesToText(patches), @"patch_patchesFromTexts: Character encoding.");
	
	diffs = [NSMutableArray arrayWithObjects:
			 [DMDiff diffWithOperation:DIFF_DELETE andText:@"`1234567890-=[]\\;',./"],
			 [DMDiff diffWithOperation:DIFF_INSERT andText:@"~!@#$%^&*()_+{}|:\"<>?"], nil];
	
	patchAsText = @"@@ -1,21 +1,21 @@\n-%601234567890-=%5B%5D%5C;',./\n+~!@#$%25%5E&*()_+%7B%7D%7C:%22%3C%3E?\n";
	STAssertEqualObjects(diffs, [(DMPatch *)[patch_parsePatchesFromText(patchAsText, NULL) objectAtIndex:0] diffs], @"patch_fromText: Character decoding.");
	
	NSMutableString *text1Mutable = [NSMutableString string];
	
	for(int x = 0; x < 100; x++)
		[text1Mutable appendString:@"abcdef"];
	
	text1 = text1Mutable;
	text2 = [text1 stringByAppendingString:@"123"];
	
	// CHANGEME: Why does this implementation produce a different, more brief patch?
	//expectedPatch = @"@@ -573,28 +573,31 @@\n cdefabcdefabcdefabcdefabcdef\n+123\n";
	patchAsText = @"@@ -597,4 +597,7 @@\n cdef\n+123\n";
	patches = patch_patchesFromTexts(text1, text2);
	STAssertEqualObjects(patchAsText, patch_patchesToText(patches), @"patch_make: Long string with repeats.");
}


- (void)test_patch_splitMaxTest
{
	// Assumes that Match_MaxBits is 32.
	PatchProperties properties = patch_defaultPatchProperties();
	properties.matchProperties.matchMaximumBits = 32;
	
	
	NSMutableArray *mutablePatches = [patch_patchesFromTexts(@"abcdefghijklmnopqrstuvwxyz01234567890", @"XabXcdXefXghXijXklXmnXopXqrXstXuvXwxXyzX01X23X45X67X89X0") mutableCopy];
	patch_splitMax(&mutablePatches, properties);
	STAssertEqualObjects(@"@@ -1,32 +1,46 @@\n+X\n ab\n+X\n cd\n+X\n ef\n+X\n gh\n+X\n ij\n+X\n kl\n+X\n mn\n+X\n op\n+X\n qr\n+X\n st\n+X\n uv\n+X\n wx\n+X\n yz\n+X\n 012345\n@@ -25,13 +39,18 @@\n zX01\n+X\n 23\n+X\n 45\n+X\n 67\n+X\n 89\n+X\n 0\n", patch_patchesToText(mutablePatches), @"Assumes that Match_MaxBits is 32 #1");
	
	mutablePatches = [patch_patchesFromTexts(@"abcdef1234567890123456789012345678901234567890123456789012345678901234567890uvwxyz", @"abcdefuvwxyz") mutableCopy];
	NSString *previousText = patch_patchesToText(mutablePatches);
	patch_splitMax(&mutablePatches, properties);
	STAssertEqualObjects(previousText, patch_patchesToText(mutablePatches), @"Assumes that Match_MaxBits is 32 #2");
	
	mutablePatches = [patch_patchesFromTexts(@"1234567890123456789012345678901234567890123456789012345678901234567890", @"abc") mutableCopy];
	patch_splitMax(&mutablePatches, properties);
	STAssertEqualObjects(@"@@ -1,32 +1,4 @@\n-1234567890123456789012345678\n 9012\n@@ -29,32 +1,4 @@\n-9012345678901234567890123456\n 7890\n@@ -57,14 +1,3 @@\n-78901234567890\n+abc\n", patch_patchesToText(mutablePatches), @"Assumes that Match_MaxBits is 32 #3");
	
	mutablePatches = [patch_patchesFromTexts(@"abcdefghij , h : 0 , t : 1 abcdefghij , h : 0 , t : 1 abcdefghij , h : 0 , t : 1", @"abcdefghij , h : 1 , t : 1 abcdefghij , h : 1 , t : 1 abcdefghij , h : 0 , t : 1") mutableCopy];
	patch_splitMax(&mutablePatches, properties);
	STAssertEqualObjects(@"@@ -2,32 +2,32 @@\n bcdefghij , h : \n-0\n+1\n  , t : 1 abcdef\n@@ -29,32 +29,32 @@\n bcdefghij , h : \n-0\n+1\n  , t : 1 abcdef\n", patch_patchesToText(mutablePatches), @"Assumes that Match_MaxBits is 32 #4");
}


- (void)test_patch_addPaddingTest
{
	PatchProperties properties = patch_defaultPatchProperties();
	
	NSMutableArray *mutablePatches = [patch_patchesFromTexts(@"", @"test") mutableCopy];
	STAssertEqualObjects(@"@@ -0,0 +1,4 @@\n+test\n", patch_patchesToText(mutablePatches), @"patch_addPadding: Both edges full.");
	patch_addPaddingToPatches(&mutablePatches, properties);
	
	STAssertEqualObjects(@"@@ -1,8 +1,12 @@\n %01%02%03%04\n+test\n %01%02%03%04\n", patch_patchesToText(mutablePatches), @"patch_addPadding: Both edges full.");
	
	mutablePatches = [patch_patchesFromTexts(@"XY", @"XtestY") mutableCopy];
	STAssertEqualObjects(@"@@ -1,2 +1,6 @@\n X\n+test\n Y\n", patch_patchesToText(mutablePatches), @"patch_addPadding: Both edges partial.");
	patch_addPaddingToPatches(&mutablePatches, properties);
	STAssertEqualObjects(@"@@ -2,8 +2,12 @@\n %02%03%04X\n+test\n Y%01%02%03\n", patch_patchesToText(mutablePatches), @"patch_addPadding: Both edges partial.");
	
	mutablePatches = [patch_patchesFromTexts(@"XXXXYYYY", @"XXXXtestYYYY") mutableCopy];
	STAssertEqualObjects(@"@@ -1,8 +1,12 @@\n XXXX\n+test\n YYYY\n", patch_patchesToText(mutablePatches), @"patch_addPadding: Both edges none.");
	patch_addPaddingToPatches(&mutablePatches, properties);
	STAssertEqualObjects(@"@@ -5,8 +5,12 @@\n XXXX\n+test\n YYYY\n", patch_patchesToText(mutablePatches), @"patch_addPadding: Both edges none.");
}


- (void)test_patch_applyTest
{
	PatchProperties properties = patch_defaultPatchProperties();
	properties.matchProperties.matchDistance = 1000;
	properties.matchProperties.matchThreshold = 0.5f;
	properties.patchDeleteThreshold = 0.5f;

	NSIndexSet *indexesOfAppliedPatches = nil;
	NSArray *patches = patch_patchesFromTextsWithProperties(@"", @"", properties);
	NSString *resultString = patch_applyPatchesToTextWithProperties(patches, @"Hello world.", &indexesOfAppliedPatches, properties);
	resultString = [resultString stringByAppendingFormat:@"\t%ld", [indexesOfAppliedPatches count]];
	STAssertEqualObjects(@"Hello world.\t0", resultString, @"patch_apply: Null case.");
	
	
	patches = patch_patchesFromTextsWithProperties(@"The quick brown fox jumps over the lazy dog.", @"That quick brown fox jumped over a lazy dog.", properties);
	NSLog(@"patches: %@", patches);
	resultString = patch_applyPatchesToTextWithProperties(patches, @"The quick brown fox jumps over the lazy dog.", &indexesOfAppliedPatches, properties);
	
	STAssertTrue([indexesOfAppliedPatches containsIndexesInRange:NSMakeRange(0, 2)], @"patch_apply: Exact match. Correct indices");
	STAssertEqualObjects(@"That quick brown fox jumped over a lazy dog.", resultString, @"patch_apply: Exact match. Text");
	
	resultString = patch_applyPatchesToTextWithProperties(patches, @"The quick red rabbit jumps over the tired tiger.", &indexesOfAppliedPatches, properties);
	STAssertTrue([indexesOfAppliedPatches containsIndexesInRange:NSMakeRange(0, 2)], @"patch_apply: Partial match");
	STAssertEqualObjects(@"That quick red rabbit jumped over a tired tiger.", resultString, @"patch_apply: Partial match.");
	
	resultString = patch_applyPatchesToTextWithProperties(patches, @"I am the very model of a modern major general.", &indexesOfAppliedPatches, properties);
	STAssertFalse([indexesOfAppliedPatches containsIndex:0] && [indexesOfAppliedPatches containsIndex:1], @"patch_apply: Failed match");
	STAssertEqualObjects(@"I am the very model of a modern major general.", resultString, @"patch_apply: Failed match.");
	
	patches = patch_patchesFromTextsWithProperties(@"x1234567890123456789012345678901234567890123456789012345678901234567890y", @"xabcy", properties);
	resultString = patch_applyPatchesToTextWithProperties(patches, @"x123456789012345678901234567890-----++++++++++-----123456789012345678901234567890y", &indexesOfAppliedPatches, properties);
	STAssertTrue([indexesOfAppliedPatches containsIndexesInRange:NSMakeRange(0, 2)], @"patch_apply: Big delete, small change");
	STAssertEqualObjects(@"xabcy", resultString, @"patch_apply: Big delete, small change.");
	
	patches = patch_patchesFromTextsWithProperties(@"x1234567890123456789012345678901234567890123456789012345678901234567890y", @"xabcy", properties);
	resultString = patch_applyPatchesToTextWithProperties(patches, @"x12345678901234567890---------------++++++++++---------------12345678901234567890y", &indexesOfAppliedPatches, properties);
	STAssertTrue([indexesOfAppliedPatches count] == 1 && [indexesOfAppliedPatches containsIndex:1], @"patch_apply: Big delete, big change 1.");
	STAssertEqualObjects(@"xabc12345678901234567890---------------++++++++++---------------12345678901234567890y", resultString, @"patch_apply: Big delete, big change 1.");
	
	properties.patchDeleteThreshold = 0.6f;
	patches = patch_patchesFromTextsWithProperties(@"x1234567890123456789012345678901234567890123456789012345678901234567890y", @"xabcy", properties);
	resultString = patch_applyPatchesToTextWithProperties(patches, @"x12345678901234567890---------------++++++++++---------------12345678901234567890y", &indexesOfAppliedPatches, properties);
	STAssertTrue([indexesOfAppliedPatches containsIndexesInRange:NSMakeRange(0, 2)], @"patch_apply: Big delete, big change 2.");
	STAssertEqualObjects(@"xabcy", resultString, @"patch_apply: Big delete, big change 2.");
	
	properties.patchDeleteThreshold = 0.5f;
	properties.matchProperties.matchThreshold = 0.0f;
	properties.matchProperties.matchDistance = 0;

	patches = patch_patchesFromTextsWithProperties(@"abcdefghijklmnopqrstuvwxyz--------------------1234567890", @"abcXXXXXXXXXXdefghijklmnopqrstuvwxyz--------------------1234567YYYYYYYYYY890", properties);
	resultString = patch_applyPatchesToTextWithProperties(patches, @"ABCDEFGHIJKLMNOPQRSTUVWXYZ--------------------1234567890", &indexesOfAppliedPatches, properties);
	STAssertTrue([indexesOfAppliedPatches count] == 1 && [indexesOfAppliedPatches containsIndex:1], @"patch_apply: Compensate for failed patch..");
	STAssertEqualObjects(@"ABCDEFGHIJKLMNOPQRSTUVWXYZ--------------------1234567YYYYYYYYYY890", resultString, @"patch_apply: Compensate for failed patch.");
	
	properties.matchProperties.matchThreshold = 0.5f;
	properties.matchProperties.matchDistance = 1000;
	
	patches = patch_patchesFromTextsWithProperties(@"", @"test", properties);
	NSString *patchesAsText = patch_patchesToText(patches);
	resultString = patch_applyPatchesToText(patches, @"", NULL);
	STAssertEqualObjects(patchesAsText, patch_patchesToText(patches), @"patch_apply: No side effects.");
	
	patches = patch_patchesFromTexts(@"The quick brown fox jumps over the lazy dog.", @"Woof");
	patchesAsText = patch_patchesToText(patches);
	resultString = patch_applyPatchesToText(patches, @"The quick brown fox jumps over the lazy dog.", NULL);
	STAssertEqualObjects(patchesAsText, patch_patchesToText(patches), @"patch_apply: No side effects with major delete.");
	
	patches = patch_patchesFromTexts(@"", @"test");
	resultString = patch_applyPatchesToText(patches, @"", &indexesOfAppliedPatches);
	STAssertTrue([indexesOfAppliedPatches count] == 1 && [indexesOfAppliedPatches containsIndex:0], @"patch_apply: Edge exact match.");
	STAssertEqualObjects(@"test", resultString, @"patch_apply: Edge exact match.");
	
	patches = patch_patchesFromTexts(@"XY", @"XtestY");
	resultString = patch_applyPatchesToText(patches, @"XY", &indexesOfAppliedPatches);
	STAssertTrue([indexesOfAppliedPatches count] == 1 && [indexesOfAppliedPatches containsIndex:0], @"patch_apply: Near edge exact match.");
	STAssertEqualObjects(@"XtestY", resultString, @"patch_apply: Near edge exact match.");
	
	patches = patch_patchesFromTexts(@"y", @"y123");
	resultString = patch_applyPatchesToText(patches, @"x", &indexesOfAppliedPatches);
	STAssertTrue([indexesOfAppliedPatches count] == 1 && [indexesOfAppliedPatches containsIndex:0], @"patch_apply: Edge partial match.");
	STAssertEqualObjects(@"x123", resultString, @"patch_apply: Edge partial match.");
}


- (void)test_speedtests
{
	NSString *text1 = [NSString stringWithContentsOfFile:@"Speedtest1.txt" encoding:NSUTF8StringEncoding error:NULL];
	NSString *text2 = [NSString stringWithContentsOfFile:@"Speedtest2.txt" encoding:NSUTF8StringEncoding error:NULL];
	
	NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
	diff_diffsBetweenTexts(text1, text2);
	NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
	
	NSLog(@"test_speedtests: Elapsed time: %.4lf", (double)duration);
}


#pragma mark Test Utility Functions


NSArray *diff_rebuildTextsFromDiffs(NSArray *diffs)
{
	NSMutableString *firstText = [NSMutableString string];
	NSMutableString *secondText = [NSMutableString string];
	
	for(DMDiff *diff in diffs) {
		if(diff.operation != DIFF_INSERT)
			[firstText appendString:diff.text];
		
		if(diff.operation != DIFF_DELETE)
			[secondText appendString:diff.text];
	}
	
	return @[firstText, secondText];
}


@end

