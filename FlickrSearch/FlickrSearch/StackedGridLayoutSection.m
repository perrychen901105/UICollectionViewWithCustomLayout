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
    __block CGFloat shortestColumnHeight = CGFLOAT_MAX;     // 最短列高
    __block NSUInteger shortestColumnIndex = 0;             // 最短列高的索引
    
    // 2        计算最短列及它的索引
    [_columnHeights enumerateObjectsUsingBlock:^(NSNumber *height, NSUInteger idx, BOOL *stop) {
        CGFloat thisColumnHeight = [height floatValue];
        if (thisColumnHeight < shortestColumnHeight) {
            shortestColumnHeight = thisColumnHeight;
            shortestColumnIndex = idx;
        }
    }];
    
    // 3        计算item的frame 列的大小，cell的Insets 和 item大小
    CGRect frame;
    frame.origin.x = _frame.origin.x + (_columnWidth * shortestColumnIndex) + _itemInsets.left;
    frame.origin.y = _frame.origin.y + shortestColumnHeight + _itemInsets.top;
    frame.size = size;
    
    // 4
    _indexToFrameMap[@(index)] = [NSValue valueWithCGRect:frame];
    
    // 5        当该item的frame的y值比分区frame的y值大，更新分区的frame
    if (CGRectGetMaxY(frame) > CGRectGetMaxY(_frame)) {
        _frame.size.height = (CGRectGetMaxY(frame) - _frame.origin.y) + _itemInsets.bottom;
    }
    
    // 6        更新列高数组。
    [_columnHeights replaceObjectAtIndex:shortestColumnIndex withObject:@(shortestColumnHeight + size.height + _itemInsets.bottom)];
}

- (CGRect)frameForItemAtIndex:(NSInteger)index
{
    return [_indexToFrameMap[@(index)] CGRectValue];
}

@end
