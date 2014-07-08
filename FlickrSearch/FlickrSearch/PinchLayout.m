//
//  PinchLayout.m
//  FlickrSearch
//
//  Created by Perry on 14-7-8.
//  Copyright (c) 2014年 RookSoft Pte. Ltd. All rights reserved.
//

#import "PinchLayout.h"

@implementation PinchLayout

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    [self applySettingsToAttributes:attributes];
    return attributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *layoutAttributes = [super layoutAttributesForElementsInRect:rect];
    
    [layoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attributes, NSUInteger idx, BOOL *stop) {
        [self applySettingsToAttributes:attributes];
    }];
    return layoutAttributes;
}

- (void)applySettingsToAttributes:(UICollectionViewLayoutAttributes*)attributes
{
    //1 设置cell 的 z-index 为 cell 索引值。意味着视图完全向内捏时第一张照片出现在照片堆最前面.
    NSIndexPath *indexPath = attributes.indexPath;
    attributes.zIndex = -indexPath.item;
    
    //2 
    CGFloat deltaX = self.pinchCenter.x - attributes.center.x;
    CGFloat deltaY = self.pinchCenter.y - attributes.center.y;
    CGFloat scale = 1.0f - self.pinchScale;
    CATransform3D transform = CATransform3DMakeTranslation(deltaX * scale, deltaY * scale, 0.0f);
    attributes.transform3D = transform;
}

- (void)setPinchCenter:(CGPoint)pinchCenter
{
    _pinchCenter = pinchCenter;
    [self invalidateLayout];
}

- (void)setPinchScale:(CGFloat)pinchScale
{
    _pinchScale = pinchScale;
    [self invalidateLayout];
}

@end
