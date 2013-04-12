/*
 * The data structure representing a diff is an NSMutableArray of Diff objects:
 * {Diff(Operation.DIFF_DELETE, "Hello"),
 *  Diff(Operation.DIFF_INSERT, "Goodbye"),
 *  Diff(Operation.DIFF_EQUAL, " world.")}
 * which means: delete "Hello", add "Goodbye" and keep " world."
 */

typedef enum {
	DIFF_DELETE = 1,
	DIFF_INSERT = 2,
	DIFF_EQUAL = 3
} DiffOperation;


#import <Foundation/Foundation.h>

@interface DMDiff :NSObject <NSCopying> {
}

@property (nonatomic, assign) DiffOperation operation;
@property (nonatomic, copy) NSString *text;

+ (id)diffWithOperation:(DiffOperation)anOperation andText:(NSString *)aText;

- (id)initWithOperation:(DiffOperation)anOperation andText:(NSString *)aText;

@end
