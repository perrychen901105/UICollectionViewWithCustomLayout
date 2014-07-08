//
//  ViewController.m
//  FlickrSearch
//
//  Created by Fahim Farook on 24/7/12.
//  Copyright (c) 2012 RookSoft Pte. Ltd. All rights reserved.
//
// API Key - 2738538d006c93bf91120fbfa537b8a7

#import "ViewController.h"

#import "Flickr.h"
#import "FlickrPhoto.h"
#import "FlickrPhotoCell.h"
#import "FlickrPhotoHeaderView.h"
#import "FlickrPhotoViewController.h"

#import "SimpleFlowLayout.h"

#import <MessageUI/MessageUI.h>

@interface ViewController () <UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *shareButton;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIView *collectionViewContainer;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *layoutSelectionControl;

@property (nonatomic, strong) NSMutableDictionary *searchResults;
@property (nonatomic, strong) NSMutableArray *searches;
@property (nonatomic, strong) Flickr *flickr;
@property (nonatomic) BOOL sharing;
@property (nonatomic, strong) NSMutableArray *selectedPhotos;

@property (nonatomic, strong) SimpleFlowLayout *layout2;

@property (nonatomic, strong) UICollectionViewFlowLayout *layout1;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_cork.png"]];
	UIImage *navBarImage = [[UIImage imageNamed:@"navbar.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(27.0f, 27.0f, 27.0f, 27.0f)];
	[self.toolbar setBackgroundImage:navBarImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
	UIImage *shareButtonImage = [[UIImage imageNamed:@"button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(8.0f, 8.0f, 8.0f, 8.0f)];
	[self.shareButton setBackgroundImage:shareButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
	UIImage *textFieldImage = [[UIImage imageNamed:@"search_field.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f)];
	[self.textField setBackground:textFieldImage];
    
	self.searches = [@[] mutableCopy];
	self.searchResults = [@{} mutableCopy];
	self.flickr = [[Flickr alloc] init];
	[self.collectionView registerNib:[UINib nibWithNibName:@"FlickrPhotoCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"MY_CELL"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"FlickrPhotoHeaderView" bundle:[NSBundle mainBundle]] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"FlickrPhotoHeaderView"];
	self.selectedPhotos = [@[] mutableCopy];
    
    self.layout1 = [[UICollectionViewFlowLayout alloc] init];
    self.layout1.scrollDirection = UICollectionViewScrollDirectionVertical;
    self.layout1.headerReferenceSize = CGSizeMake(0.0f, 90.0f);
    
    self.layout2 = [[SimpleFlowLayout alloc] init];
    self.layout2.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleLongPressGesture:)];
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateRecognized) {
        CGPoint tapPoint = [recognizer locationInView:self.collectionView];
        // 根据按的位置获取item
        NSIndexPath *item = [self.collectionView indexPathForItemAtPoint:tapPoint];
        if (item) {
            NSString *searchTerm = self.searches[item.item];
            [self.searches removeObjectAtIndex:item.item];
            [self.searchResults removeObjectForKey:searchTerm];
            
            [self.collectionView performBatchUpdates:^{
                [self.collectionView deleteItemsAtIndexPaths:@[item]];
            } completion:nil];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self layoutSelectionTapped:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)shareButtonTapped:(id)sender {
    UIBarButtonItem *shareButton = (UIBarButtonItem *)sender;
    if (!self.sharing) {
        self.sharing = YES;
        [shareButton setStyle:UIBarButtonItemStyleDone];
        [shareButton setTitle:@"Done"];
        [self.collectionView setAllowsMultipleSelection:YES];
    } else {
        self.sharing = NO;
        [shareButton setStyle:UIBarButtonItemStyleBordered];
        [shareButton setTitle:@"Share"];
        [self.collectionView setAllowsMultipleSelection:NO];
		
        if ([self.selectedPhotos count] > 0) {
            [self showMailComposerAndSend];
        }
		
        for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        [self.selectedPhotos removeAllObjects];
    }
}

- (IBAction)layoutSelectionTapped:(id)sender {
    switch (self.layoutSelectionControl.selectedSegmentIndex) {
        case 0:
        default: {
            self.collectionView.collectionViewLayout = self.layout1;
            [self.collectionView removeGestureRecognizer:self.longPressGestureRecognizer];
        }
            break;
        case 1: {
            self.collectionView.collectionViewLayout = self.layout2;
            [self.collectionView addGestureRecognizer:self.longPressGestureRecognizer];
        }
            break;
        case 2: {
        }
            break;
        case 3: {
        }
            break;
    }
    [self.collectionView reloadData];
    [self.collectionView setContentOffset:CGPointZero animated:NO];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.flickr searchFlickrForTerm:textField.text completionBlock:^(NSString *searchTerm, NSArray *results, NSError *error) {
        if (results && [results count] > 0) {
            if (![self.searches containsObject:searchTerm]) {
                NSLog(@"Found %d photos matching %@", [results count],searchTerm);
                [self.searches addObject:searchTerm];
                self.searchResults[searchTerm] = results;
			}
			dispatch_async(dispatch_get_main_queue(), ^{
                // RUN AFTER SEARCH HAS FINISHED
                if (self.collectionView.collectionViewLayout == self.layout2) {
                    [self.collectionView performBatchUpdates:^{
                        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.searches.count-1 inSection:0]]];
                    } completion:nil];
                } else {
                    [self.collectionView performBatchUpdates:^{
                        NSInteger newSection = (self.searches.count - 1);
                        for (NSInteger i = 0; i < [results count]; i++) {
                            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:i inSection:newSection]]];
                        }
                        [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:newSection]];
                    } completion:nil];
                }
			});
		} else {
			NSLog(@"Error searching Flickr: %@", error.localizedDescription);
		}
	}];
	
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)section {
    if (cv == self.collectionView) {
        if (cv.collectionViewLayout == self.layout2) {
            return [self.searches count];
        } else {
            NSString *searchTerm = self.searches[section];
            return [self.searchResults[searchTerm] count];
        }
    }
    return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)cv {
    if (cv == self.collectionView) {
        if (cv.collectionViewLayout == self.layout2) {
            return 1;
        } else {
            return [self.searches count];
        }
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FlickrPhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"MY_CELL" forIndexPath:indexPath];
    
    FlickrPhoto *photo = nil;
    if (cv == self.collectionView) {
        if (cv.collectionViewLayout == self.layout2) {
            NSString *searchTerm = self.searches[indexPath.item];
            photo = self.searchResults[searchTerm][0];
        } else {
            NSString *searchTerm = self.searches[indexPath.section];
            photo = self.searchResults[searchTerm][indexPath.item];
        }

    }
    cell.photo = photo;
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)cv viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    FlickrPhotoHeaderView *headerView = [cv dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"FlickrPhotoHeaderView" forIndexPath:indexPath];
    NSString *searchTerm = nil;
    if (cv == self.collectionView) {
        searchTerm = self.searches[indexPath.section];
    }
    [headerView setSearchText:searchTerm];
    return headerView;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.sharing) {
		NSString *searchTerm = self.searches[indexPath.section];
		FlickrPhoto *photo = self.searchResults[searchTerm][indexPath.item];
		[self.selectedPhotos addObject:photo];
	} else {
        FlickrPhoto *photo = nil;
        if (cv == self.collectionView) {
            if (cv.collectionViewLayout == self.layout2) {
                NSString *searchTerm = self.searches[indexPath.item];
                photo = self.searchResults[searchTerm][0];
            } else {
                NSString *searchTerm = self.searches[indexPath.section];
                photo = self.searchResults[searchTerm][indexPath.item];
            }

        }
		[self performSegueWithIdentifier:@"ShowFlickrPhoto" sender:photo];
		[self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
	}
}

- (void)collectionView:(UICollectionView *)cv didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.sharing) {
		NSString *searchTerm = self.searches[indexPath.section];
		FlickrPhoto *photo = self.searchResults[searchTerm][indexPath.item];
		[self.selectedPhotos removeObject:photo];
	}
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout*)cvl sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    FlickrPhoto *photo = nil;
    if (cv == self.collectionView) {
        if (cvl == self.layout2) {
            NSString *searchTerm = self.searches[indexPath.item];
            photo = self.searchResults[searchTerm][0];
        } else {
            NSString *searchTerm = self.searches[indexPath.section];
            photo = self.searchResults[searchTerm][indexPath.item];
        }
    }
    
    CGSize retval = photo.thumbnail.size.width > 0.0f ? photo.thumbnail.size : CGSizeMake(100.0f, 100.0f);
    retval.height += 35.0f;
    retval.width += 35.0f;
    return retval;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout*)cvl insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(50.0f, 20.0f, 50.0f, 20.0f);
}


#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowFlickrPhoto"]) {
        FlickrPhotoViewController *flickrPhotoViewController = segue.destinationViewController;
        flickrPhotoViewController.flickrPhoto = sender;
    }
}

- (void)showMailComposerAndSend {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
		
        [mailer setSubject:@"Check out these Flickr Photos"];
		
        NSMutableString *emailBody = [NSMutableString string];
        for( FlickrPhoto *flickrPhoto in self.selectedPhotos) {
            NSString *url = [Flickr flickrPhotoURLForFlickrPhoto:flickrPhoto size:@"m"];
            [emailBody appendFormat:@"<div><img src='%@'></div><br>",url];
        }
		
        [mailer setMessageBody:emailBody isHTML:YES];
		
        [self presentViewController:mailer animated:YES completion:^{}];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mail Failure"
                                                        message:@"Your device doesn't support in-app email"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:^{}];
}

@end
