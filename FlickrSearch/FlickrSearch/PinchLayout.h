//
//  PinchLayout.h
//  FlickrSearch
//
//  Created by Perry on 14-7-8.
//  Copyright (c) 2014年 RookSoft Pte. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PinchLayout : UICollectionViewFlowLayout
@property (nonatomic, assign) CGFloat pinchScale;
@property (nonatomic, assign) CGPoint pinchCenter;
@end
