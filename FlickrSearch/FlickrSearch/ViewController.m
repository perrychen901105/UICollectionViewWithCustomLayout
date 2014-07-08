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

#import "PinchLayout.h"
#import "SimpleFlowLayout.h"

#import <MessageUI/MessageUI.h>

static const CGFloat kMinScale = 1.0f;
static const CGFloat kMaxScale = 3.0f;

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

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchOutGestureRecognizer;
@property (nonatomic, strong) UICollectionView *currentPinchCollectionView;
@property (nonatomic, strong) NSIndexPath *currentPinchedItem;

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

    self.pinchOutGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(handlePinchOutGesture:)];
    

}

- (void)handlePinchInGesture:(UIPinchGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // 1
        self.collectionView.alpha = 0.0f;
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        // 2
        CGFloat theScale = 1.0f / recognizer.scale;
        theScale = MIN(theScale, kMaxScale);
        theScale = MAX(theScale, kMinScale);
        
        CGFloat theScalePct = 1.0f - ((theScale - kMinScale) / (kMaxScale - kMinScale));
        
        // 3
        PinchLayout *layout = (PinchLayout*)self.currentPinchCollectionView.collectionViewLayout;
        layout.pinchScale = theScalePct;
        layout.pinchCenter = [recognizer locationInView:self.collectionView];
        
        // 4
        self.collectionView.alpha = 1.0f - theScalePct;
    } else {
        // 5
        self.collectionView.alpha = 1.0f;
        
        [self.currentPinchCollectionView removeFromSuperview];
        self.currentPinchCollectionView = nil;
        self.currentPinchedItem = nil;
    }
}

- (void)handlePinchOutGesture:(UIPinchGestureRecognizer*)recognizer
{
    // 1
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // 2 如果手势开始，获取缩放发生的点。然后通过该点获取发生缩放的cell
        CGPoint pinchPoint = [recognizer locationInView:self.collectionView];
        NSIndexPath *pinchedItem = [self.collectionView indexPathForItemAtPoint:pinchPoint];
        if (pinchedItem) {
            // 3 如果找到item, 接着将索引路径赋值给之前创建的属性。
            self.currentPinchedItem = pinchedItem;
            
            // 4 按要求创建一个新的缩放布局，初始化缩放大小为0.
            PinchLayout *layout = [[PinchLayout alloc] init];
            layout.itemSize = CGSizeMake(200.0f, 200.0f);
            layout.minimumInteritemSpacing = 20.0f;
            layout.minimumLineSpacing = 20.0f;
            layout.sectionInset = UIEdgeInsetsMake(20.0f, 20.0f, 20.0f, 20.0f);
            layout.headerReferenceSize = CGSizeMake(0.0f, 90.0f);
            layout.pinchScale = 0.0f;
            
            // 5 使用设置到缩放布局的布局创建新的集合视图
            self.currentPinchCollectionView = [[UICollectionView alloc] initWithFrame:self.collectionView.frame collectionViewLayout:layout];
            self.currentPinchCollectionView.backgroundColor = [UIColor clearColor];
            self.currentPinchCollectionView.delegate = self;
            self.currentPinchCollectionView.dataSource = self;
            self.currentPinchCollectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.currentPinchCollectionView registerNib:[UINib nibWithNibName:@"FlickrPhotoCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"MY_CELL"];
            [self.currentPinchCollectionView registerNib:[UINib nibWithNibName:@"FlickrPhotoHeaderView" bundle:[NSBundle mainBundle]] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"FlickrPhotoHeaderView"];
            
            // 6
            [self.collectionViewContainer addSubview:self.currentPinchCollectionView];
            
            // 7
            UIPinchGestureRecognizer *recognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchInGesture:)];
            [_currentPinchCollectionView addGestureRecognizer:recognizer];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (self.currentPinchedItem) {
            // 8
            CGFloat theScale = recognizer.scale;
            theScale = MIN(theScale, kMaxScale);
            theScale = MAX(theScale, kMinScale);
            
            // 9
            CGFloat theScalePct = (theScale -kMinScale) / (kMaxScale - kMinScale);
            
            // 10
            PinchLayout *layout = (PinchLayout *)_currentPinchCollectionView.collectionViewLayout;
            layout.pinchScale = theScalePct;
            layout.pinchCenter = [recognizer locationInView:self.collectionView];
            
            // 11
            self.collectionView.alpha = 1.0f - theScalePct;
        }
    } else {
        if (self.currentPinchedItem) {
            // 12
            PinchLayout *layout = (PinchLayout *)_currentPinchCollectionView.collectionViewLayout;
            layout.pinchScale = 1.0f;
            self.collectionView.alpha = 0.0f;
        }
    }
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
            [self.collectionView removeGestureRecognizer:self.pinchOutGestureRecognizer];
        }
            break;
        case 1: {
            self.collectionView.collectionViewLayout = self.layout2;
            [self.collectionView addGestureRecognizer:self.longPressGestureRecognizer];
            [self.collectionView addGestureRecognizer:self.pinchOutGestureRecognizer];
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
    } else if (cv == self.currentPinchCollectionView) {
        NSString *searchTerm = self.searches[self.currentPinchedItem.item];
        return [self.searchResults[searchTerm] count];
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
    } else if (cv == self.currentPinchCollectionView) {
        return 1;
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

    } else if (cv == self.currentPinchCollectionView) {
        NSString *searchTerm = self.searches[self.currentPinchedItem.item];
        photo = self.searchResults[searchTerm][indexPath.item];
    }
    cell.photo = photo;
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)cv viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    FlickrPhotoHeaderView *headerView = [cv dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"FlickrPhotoHeaderView" forIndexPath:indexPath];
    NSString *searchTerm = nil;
    if (cv == self.collectionView) {
        searchTerm = self.searches[indexPath.section];
    } else if (cv == self.currentPinchCollectionView) {
        searchTerm = self.searches[self.currentPinchedItem.item];
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

        } else if (cv == self.currentPinchCollectionView) {
            NSString *searchTerm = self.searches[self.currentPinchedItem.item];
            photo = self.searchResults[searchTerm][indexPath.item];
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
    } else if (cv == self.currentPinchCollectionView) {
        NSString *searchTerm = self.searches[self.currentPinchedItem.item];
        photo = self.searchResults[searchTerm][indexPath.item];
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
