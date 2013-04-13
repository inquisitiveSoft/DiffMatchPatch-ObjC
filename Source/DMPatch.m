#import "DMPatch.h"
#import "DMDiff.h"

#import "DiffMatchPatchInternals.h"			// DMPatch uses the MAX_OF_CONST_AND_DIFF macro
#import "DiffMatchPatchCFUtilities.h"
#import "NSString+UriCompatibility.h"


@implementation DMPatch


- (id)init
{
	self = [super init];
	
	if(self) {
		self.diffs = [NSMutableArray array];
	}
	
	return self;
}


- (id)copyWithZone:(NSZone *)zone
{
	DMPatch *newPatch = [[[self class] allocWithZone:zone] init];
	
	newPatch.diffs = [[NSMutableArray alloc] initWithArray:self.diffs copyItems:YES];
	newPatch.start1 = self.start1;
	newPatch.start2 = self.start2;
	newPatch.length1 = self.length1;
	newPatch.length2 = self.length2;
	
	return newPatch;
}


/**
 * Emulate GNU diff's format.
 * Header: @@ -382,8 +481,9 @@
 * Indicies are printed as 1-based, not 0-based.
 * @return The GNU diff NSString.
 */
- (NSString *)description
{
	NSString *coords1;
	NSString *coords2;
	
	if(self.length1 == 0) {
		coords1 = [NSString stringWithFormat:@"%lu,0",
				   (unsigned long)self.start1];
	} else if(self.length1 == 1) {
		coords1 = [NSString stringWithFormat:@"%lu",
				   (unsigned long)self.start1 + 1];
	} else {
		coords1 = [NSString stringWithFormat:@"%lu,%lu",
				   (unsigned long)self.start1 + 1, (unsigned long)self.length1];
	}
	
	if(self.length2 == 0) {
		coords2 = [NSString stringWithFormat:@"%lu,0",
				   (unsigned long)self.start2];
	} else if(self.length2 == 1) {
		coords2 = [NSString stringWithFormat:@"%lu",
				   (unsigned long)self.start2 + 1];
	} else {
		coords2 = [NSString stringWithFormat:@"%lu,%lu",
				   (unsigned long)self.start2 + 1, (unsigned long)self.length2];
	}
	
	NSMutableString *text = [NSMutableString stringWithFormat:@"@@ -%@ +%@ @@\n",
							 coords1, coords2];
	
	// Escape the body of the patch with %xx notation.
	for(DMDiff *aDiff in self.diffs) {
		switch(aDiff.operation) {
			case DIFF_INSERT:
				[text appendString:@"+"];
				break;
				
			case DIFF_DELETE:
				[text appendString:@"-"];
				break;
				
			case DIFF_EQUAL:
				[text appendString:@" "];
				break;
		}
		
		[text appendString:[aDiff.text encodedURIString]];
		[text appendString:@"\n"];
	}
	
	return text;
}



/**
 * Increase the context until it is unique,
 * but don't let the pattern expand beyond DIFF_MATCH_MAX_BITS.
 * @param patch The patch to grow.
 * @param text Source text.
 */

- (void)addContext:(NSString *)text withMargin:(NSInteger)patchMargin maximumBits:(NSUInteger)maximumBits
{
	if(text.length == 0)
		return;
	
	NSString *pattern = [text substringWithRange:NSMakeRange(self.start2, self.length1)];
	NSUInteger padding = 0;
	
	// Look for the first and last matches of pattern in text.  If two
	// different matches are found, increase the pattern length.
	while([text rangeOfString:pattern options:NSLiteralSearch].location
		!= [text rangeOfString:pattern options:(NSLiteralSearch | NSBackwardsSearch)].location
			&& pattern.length < (maximumBits - patchMargin - patchMargin)) {
		padding += patchMargin;
		pattern = (__bridge_transfer NSString *)diff_CFStringCreateJavaSubstring((__bridge CFStringRef)text, MAX_OF_CONST_AND_DIFF(0, self.start2, padding), MIN(text.length, self.start2 + self.length1 + padding));
	}
	
	// Add one chunk for good luck.
	padding += patchMargin;
	
	// Add the prefix.
	NSString *prefix = (__bridge_transfer NSString *)diff_CFStringCreateJavaSubstring((__bridge CFStringRef)text, MAX_OF_CONST_AND_DIFF(0, self.start2, padding), self.start2);
	
	if(prefix.length != 0) {
		[self.diffs insertObject:[DMDiff diffWithOperation:DIFF_EQUAL andText:prefix] atIndex:0];
	}
	
	// Add the suffix.
	NSString *suffix = (__bridge_transfer NSString *)diff_CFStringCreateJavaSubstring((__bridge CFStringRef)text, (self.start2 + self.length1), MIN(text.length, self.start2 + self.length1 + padding));
	if(suffix.length != 0) {
		[self.diffs addObject:[DMDiff diffWithOperation:DIFF_EQUAL andText:suffix]];
	}
	
	// Roll back the start points.
	self.start1 -= prefix.length;
	self.start2 -= prefix.length;
	// Extend the lengths.
	self.length1 += prefix.length + suffix.length;
	self.length2 += prefix.length + suffix.length;
}


@end