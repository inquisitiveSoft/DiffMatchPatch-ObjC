#import "DMDiff.h"


@implementation DMDiff

/**
 * Constructor.  Initializes the diff with the provided values.
 * @param operation One of DIFF_INSERT, DIFF_DELETE or DIFF_EQUAL.
 * @param text The text being applied.
 */
+ (id)diffWithOperation:(DiffOperation)anOperation andText:(NSString *)aText
{
	return [[self alloc] initWithOperation:anOperation andText:aText];
}


- (id)initWithOperation:(DiffOperation)anOperation andText:(NSString *)aText
{
	self = [super init];
	
	if(self) {
		self.operation = anOperation;
		self.text = aText;
	}
	
	return self;
}


- (id)copyWithZone:(NSZone *)zone
{
	return [[[self class] allocWithZone:zone] initWithOperation:self.operation andText:self.text];
}


/**
 * Display a human-readable version of this Diff.
 * @return text version.
 */
- (NSString *)description
{
	NSString *prettyText = [self.text stringByReplacingOccurrencesOfString:@"\n" withString:@"\u00b6"];
	NSString *operationName = nil;
	
	switch(self.operation) {
		case DIFF_DELETE:
			operationName = @"DELETE";
			break;
			
		case DIFF_INSERT:
			operationName = @"INSERT";
			break;
			
		case DIFF_EQUAL:
			operationName = @"EQUAL";
			break;
			
		default:
			break;
	}
	
	return [NSString stringWithFormat:@"%@ (%@,\"%@\")", [super description], operationName, prettyText];
}


/**
 * Is this Diff equivalent to another Diff?
 * @param obj Another Diff to compare against.
 * @return YES or NO.
 */
- (BOOL)isEqual:(id)obj
{
	// If parameter is nil return NO.
	if(obj == nil)
		return NO;
	
	// If parameter cannot be cast to Diff return NO.
	if(![obj isKindOfClass:[DMDiff class]])
		return NO;
	
	// Return YES if the fields match.
	DMDiff *p = (DMDiff *)obj;
	return p.operation == self.operation && [p.text isEqualToString:self.text];
}

- (BOOL)isEqualToDiff:(DMDiff *)obj
{
	// If parameter is nil return NO.
	if(obj == nil)
		return NO;
	
	// Return YES if the fields match.
	return obj.operation == self.operation && [obj.text isEqualToString:self.text];
}

- (NSUInteger)hash
{
	return [_text hash] ^ (NSUInteger)_operation;
}

@end
