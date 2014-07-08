//
//  StackedGridLayout.h
//  FlickrSearch
//
//  Created by Perry on 14-7-8.
//  Copyright (c) 2014年 RookSoft Pte. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol StackedGridLayoutDelegate <UICollectionViewDelegate>

// 1 分区的列个数
- (NSInteger)collectionView:(UICollectionView*)cv
                     layout:(UICollectionViewLayout*)cvl
   numberOfColumnsInSection:(NSInteger)section;

// 2 返回item 大小，给出列将变成的宽度
- (CGSize)collectionView:(UICollectionView*)cv
                  layout:(UICollectionViewLayout*)cvl
    sizeForItemWithWidth:(CGFloat)width
             atIndexPath:(NSIndexPath *)indexPath;

// 3 返回给定 item 的 insets
- (UIEdgeInsets)collectionView:(UICollectionView*)cv
                        layout:(UICollectionViewLayout*)cvl
   itemInsetsForSectionAtIndex:(NSInteger)section;
@end


@interface StackedGridLayout : UICollectionViewFlowLayout
@property (nonatomic, assign) CGFloat headerHeight;     //每个分区表头是多大.
@end
