//
//  FlickrPhotoCell.m
//  FlickrSearch
//
//  Created by Fahim Farook on 24/7/12.
//  Copyright (c) 2012 RookSoft Pte. Ltd. All rights reserved.
//

#import "FlickrPhotoCell.h"
#import "FlickrPhoto.h"

#import <QuartzCore/QuartzCore.h>

@implementation FlickrPhotoCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIView *bgView = [[UIView alloc] initWithFrame:self.backgroundView.frame];
        bgView.backgroundColor = [UIColor blueColor];
        bgView.layer.borderColor = [[UIColor whiteColor] CGColor];
        bgView.layer.borderWidth = 4;
        self.selectedBackgroundView = bgView;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    const CGRect bounds = self.bounds;
    self.imageView.frame = CGRectMake(20.0f, 40.0f, bounds.size.width - 40.0f, bounds.size.height - 60.0f);
}

- (void)setPhoto:(FlickrPhoto *)photo {
    if (_photo != photo) {
        _photo = photo;
    }
    self.imageView.image = _photo.thumbnail;
}

@end
