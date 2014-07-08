//
//  FlickrPhotoViewController.m
//  FlickrSearch
//
//  Created by Fahim Farook on 25/7/12.
//  Copyright (c) 2012 RookSoft Pte. Ltd. All rights reserved.
//

#import "FlickrPhotoViewController.h"
#import "Flickr.h"
#import "FlickrPhoto.h"

@interface FlickrPhotoViewController ()

@property (weak) IBOutlet UIImageView *imageView;
@end

@implementation FlickrPhotoViewController

- (IBAction)done:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.flickrPhoto.largeImage) {
        self.imageView.image = self.flickrPhoto.largeImage;
    } else {
        self.imageView.image = self.flickrPhoto.thumbnail;
        [Flickr loadImageForPhoto:self.flickrPhoto thumbnail:NO
				  completionBlock:^(UIImage *photoImage, NSError *error) {
					  if (!error) {
						  dispatch_async(dispatch_get_main_queue(), ^{
							  self.imageView.image =
							  self.flickrPhoto.largeImage;
						  });
					  }
				  }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
