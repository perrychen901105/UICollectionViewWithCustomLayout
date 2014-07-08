//
//  StackedGridLayoutSection.m
//  FlickrSearch
//
//  Created by Perry on 14-7-8.
//  Copyright (c) 2014年 RookSoft Pte. Ltd. All rights reserved.
//

#import "StackedGridLayoutSection.h"

@interface StackedGridLayoutSection () {
    CGRect _frame;      //整个分区当前frame
    UIEdgeInsets _itemInsets;       // 每个item 的 insets
    CGFloat _columnWidth;       // 每列的宽度
    NSMutableArray *_columnHeights;         // 包含每列当前高度的数组
    NSMutableDictionary *_indexToFrameMap;      // 将item索引映射到该项frame的字典
}

@end

@implementation StackedGridLayoutSection

- (id)initWithOrigin:(CGPoint)origin
               width:(CGFloat)width
             columns:(NSInteger)columns
          itemInsets:(UIEdgeInsets)itemInsets
{
    if ((self = [super init])) {
        _frame = CGRectMake(origin.x, origin.y, width, 0.0f);
        _itemInsets = itemInsets;
        _columnWidth = floorf(width / columns);
        _columnHeights = [NSMutableArray new];
        _indexToFrameMap = [NSMutableDictionary new];
        
        for (NSInteger i = 0; i < columns; i++) {
            [_columnHeights addObject:@(0.0f)];
        }
    }
    return self;
}

- (CGRect)frame
{
    return _frame;
}

- (CGFloat)columnWidth
{
    return _columnWidth;
}

- (NSInteger)numberOfItems
{
    return _indexToFrameMap.count;
}

- (void)addItemOfSize:(CGSize)size
             forIndex:(NSUInteger)index
{
    // 1
    __block CGFloat shortestColumnHeight = CGFLOAT_MAX;
}

- (CGRect)frameForItemAtIndex:(NSInteger)index
{

}

@end
