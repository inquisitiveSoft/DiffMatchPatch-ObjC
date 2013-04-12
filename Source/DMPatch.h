#import <Foundation/Foundation.h>


@interface DMPatch : NSObject <NSCopying> {
}

@property (nonatomic, strong) NSMutableArray *diffs;
@property (nonatomic, assign) NSUInteger start1;
@property (nonatomic, assign) NSUInteger start2;
@property (nonatomic, assign) NSUInteger length1;
@property (nonatomic, assign) NSUInteger length2;

- (void)addContext:(NSString *)text withMargin:(NSInteger)patchMargin;

@end