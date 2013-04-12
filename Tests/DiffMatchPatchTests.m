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


- (void)testDiffingToDeltas
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
