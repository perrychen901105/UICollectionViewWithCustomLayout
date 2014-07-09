//
//  CoverFlowLayout.m
//  FlickrSearch
//
//  Created by Perry on 14-7-9.
//  Copyright (c) 2014年 RookSoft Pte. Ltd. All rights reserved.
//

#import "CoverFlowLayout.h"

@implementation CoverFlowLayout

static const CGFloat kMaxDistancePercentage = 0.3f;
static const CGFloat kMaxRotation = (CGFloat)(50.0 * (M_PI / 180.0));
static const CGFloat kMaxZoom = 0.3f;

- (id)init
{
    if ((self = [super init])) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.minimumLineSpacing = 10000.0f;
    }
    return self;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    // 1 visibleRect 是collection view的可视矩形，第二个是距离中心点的最大距离值
    CGRect visibleRect = (CGRect){.origin = self.collectionView.contentOffset,
        .size = self.collectionView.bounds.size};
    CGFloat maxDistance = visibleRect.size.width * kMaxDistancePercentage;
    
    // 2 接着由于是UICollectionViewFlowLayout的子类，用超累获取矩形内的cell列表。
    NSArray *array = [super layoutAttributesForElementsInRect:rect];
    for (UICollectionViewLayoutAttributes *attributes in array) {
        // 3 遍历属性，首先获得当前可视矩形的中心点到cell的距离。
        CGFloat distance = CGRectGetMidX(visibleRect) - attributes.center.x;
        
        // 4 标准化该距离，将该距离除以最大距离获得视图中心到任何方向最远点的直线距离百分比。然后限制在1 和 -1之间
        CGFloat normalizedDistance = distance / maxDistance;
        normalizedDistance = MIN(normalizedDistance, 1.0f);
        normalizedDistance = MAX(normalizedDistance, -1.0f);
        
        // 5 计算旋转角度和缩放大小
        CGFloat rotation = normalizedDistance * kMaxRotation;
        CGFloat zoom = 1.0f + ((1.0f - ABS(normalizedDistance)) * kMaxZoom);
        
        // 6
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = 1.0 / -1000.0;
        transform = CATransform3DRotate(transform,
                                        rotation,
                                        0.0f,
                                        1.0f,
                                        0.0f);
        transform = CATransform3DScale(transform,
                                       zoom,
                                       zoom,
                                       0.0f);
        attributes.transform3D = transform;
    }
    // 7
    return array;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    // 1 创建偏移量调整，第二个是建议偏移量的水平中心值，根据建议偏移量的x值加上视图宽度的一半计算得到。
    CGFloat offsetAdjustment = CGFLOAT_MAX;
    CGFloat horizontalCenter = proposedContentOffset.x + (CGRectGetWidth(self.collectionView.bounds) / 2.0f);
    
    // 2 通过建议偏移量和视图大小计算目标矩形，接着重建该矩形的布局属性。。这些属性表示在视图结束动画时区域内可见的cell。
    CGRect targetRect = CGRectMake(proposedContentOffset.x, 0.0f, self.collectionView.bounds.size.width,
                                   self.collectionView.bounds.size.height);
    NSArray *array = [super layoutAttributesForElementsInRect:targetRect];
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in array) {
        // 3 遍历数组并找出中心离期望矩形最近的cell，offsetAdjustment变量等于视图停在cell上时期望举行正好移动到该位置的距离。
        CGFloat distanceFromCenter = layoutAttributes.center.x - horizontalCenter;
        if (ABS(distanceFromCenter) < ABS(offsetAdjustment)) {
            offsetAdjustment = distanceFromCenter;
        }
    }
    
    // 4
    return CGPointMake(proposedContentOffset.x + offsetAdjustment, proposedContentOffset.y);
}


@end
