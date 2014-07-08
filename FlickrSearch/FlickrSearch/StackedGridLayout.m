//
//  StackedGridLayout.m
//  FlickrSearch
//
//  Created by Perry on 14-7-8.
//  Copyright (c) 2014年 RookSoft Pte. Ltd. All rights reserved.
//

#import "StackedGridLayout.h"
#import "StackedGridLayoutSection.h"

@interface StackedGridLayout () {
    __weak id <StackedGridLayoutDelegate> _myDelegate;
    
    NSMutableArray *_sectionData;
    CGFloat _height;
}

@end

@implementation StackedGridLayout

- (void)prepareLayout
{
    // 1
    [super prepareLayout];
    
    // 2    创建内部状态，存储委托为所需类型的变量
    _myDelegate = (id <StackedGridLayoutDelegate>) self.collectionView.delegate;
    _sectionData = [NSMutableArray new];
    _height = 0.0f;
    
    // 3    创建一堆会被经常使用的变量，首先是当前原点，用于追踪当分区被创建时你当前在collection View的位置。第二个是分区的个数，通过请求collection view 来确定。
    CGPoint currentOrigin = CGPointZero;
    NSInteger numberOfSections = self.collectionView.numberOfSections;
    
    // 4    循环遍历分区个数
    for (NSInteger i = 0; i < numberOfSections; i++) {
        // 5    每个分区的第一件事是通过分区表头高度增加布局的高度。能确保分区开始前有足够的空间给分区表头。你还要更新当前的原点反映这个新的高度。
        _height += self.headerHeight;
        currentOrigin.y = _height;
        
        // 6    获取分区的列数量，item数量和item的insets
        NSInteger numberOfColumns = [_myDelegate collectionView:self.collectionView layout:self numberOfColumnsInSection:i];
        
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:i];
        
        UIEdgeInsets itemInsets = [_myDelegate collectionView:self.collectionView layout:self itemInsetsForSectionAtIndex:i];
        
        
        // 7    创建一个新的分区对象，传入各种需要的信息。
        StackedGridLayoutSection *section = [[StackedGridLayoutSection alloc] initWithOrigin:currentOrigin width:self.collectionView.bounds.size.width columns:numberOfColumns itemInsets:itemInsets];
        
        // 8    循环遍历每个item
        for (NSInteger j = 0; j < numberOfItems; j++) {
            // 9    根据嵌入列宽度内的适量长度计算item的宽度。接着根据item所需的宽度向委托请求Item 的大小
            CGFloat itemWidth = (section.columnWidth - section.itemInsets.left - section.itemInsets.right);
            NSLog(@"the item width is %f",itemWidth);
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:j inSection:i];
            CGSize itemSize = [_myDelegate collectionView:self.collectionView layout:self sizeForItemWithWidth:itemWidth atIndexPath:itemIndexPath];
            
            // 10   一旦知道item大小，就通知分区添加该项
            [section addItemOfSize:itemSize forIndex:j];
        }
        
        // 11
        [_sectionData addObject:section];
        
        // 12
        _height += section.frame.size.height;
        currentOrigin.y = _height;
    }
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake(self.collectionView.bounds.size.width, _height);
}

@end
