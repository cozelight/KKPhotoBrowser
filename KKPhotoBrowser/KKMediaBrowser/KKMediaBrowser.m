//
//  KKMediaBrowser.m
//  KKPhotoBrowser
//
//  Created by coze on 2017/5/26.
//  Copyright © 2017年 kook.sdk. All rights reserved.
//

#import "KKMediaBrowser.h"
#import "KKMediaPhotoCell.h"
#import "KKMediaGifCell.h"
#import "KKMediaVideoCell.h"
#import "KKMediaDisplayView.h"
#import "KKView+Base.h"
#import <Masonry.h>
#import <YYWebImage.h>

#define KKIsiPhoneX (([[UIScreen mainScreen] bounds].size.height-812)?NO:YES)
#define KKiPhoneXBottomHeight 34

static NSString * const kMediaPhotoCellIdentifier = @"kMediaPhotoCellIdentifier";
static NSString * const kMediaGifCellIdentifier = @"kMediaGifCellIdentifier";
static NSString * const kMediaVideoCellIdentifier = @"kMediaVideoCellIdentifier";

@interface KKMediaCollectionView : UICollectionView

@end

@interface KKMediaBrowser ()
<
UIGestureRecognizerDelegate,
UICollectionViewDelegate,
UICollectionViewDataSource,
KKMediaCellDelegate
>
{
    // Data
    NSUInteger _mediaCount;
    NSMutableArray *_mediaArray;
    NSArray *_fixedMediaArray; // Provided via init
    NSArray *_viewStates;
    
    // Paging
    NSUInteger _currentPageIndex;
    NSUInteger _previousPageIndex;
    CGRect _previousLayoutBounds;
    CGFloat _offsetItemCount;
    
    // Navigation & controls
    BOOL _isControlHidden;
    
    // Appearance
    BOOL _previousNavBarHidden;
    BOOL _previousNavBarTranslucent;
    UIBarStyle _previousNavBarStyle;
    UIStatusBarStyle _previousStatusBarStyle;
    UIColor *_previousNavBarTintColor;
    UIColor *_previousNavBarBarTintColor;
    UIBarButtonItem *_previousViewControllerBackButton;
    UIImage *_previousNavigationBarBackgroundImageDefault;
    UIImage *_previousNavigationBarBackgroundImageLandscapePhone;
    
    // Misc
    BOOL _hasBelongedToViewController;
    BOOL _isVCBasedStatusBarAppearance;
    BOOL _rotating;
    BOOL _viewIsActive;
    BOOL _statusBarShouldBeHidden;
    BOOL _displayActionButton;
    BOOL _leaveStatusBarAlone;
    BOOL _didSavePreviousStateOfNavBar;
    BOOL _viewHasAppearedInitially;
    UIWindow *_applicationWindow;
}

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGesture;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;

@property (nonatomic, strong) KKMediaCollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *collectionViewLayout;
@property (nonatomic, weak) UIAlertController *actionSheet;
@property (nonatomic, strong) NSArray<__kindof UIView<KKMediaSupplementaryViewProtocol>*> *supplementaryViews;

@end

@implementation KKMediaBrowser

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _initialisation];
    }
    return self;
}

- (instancetype)initWithMediaArray:(NSArray *)mediaArray {
    return [self initWithMediaArray:mediaArray initialIndex:0 animatedFromViews:nil];
}

- (instancetype)initWithDataSource:(id<KKMediaBrowserDataSource>)dataSource {
    return [self initWithDataSource:dataSource initialIndex:0];
}

- (instancetype)initWithMediaArray:(NSArray *)mediaArray initialIndex:(NSUInteger)index animatedFromViews:(NSArray *)animatedFromViews {
    self = [self init];
    if (self) {
        _fixedMediaArray = mediaArray;
        _currentPageIndex = index;
        if (animatedFromViews != nil) {
            _viewStates = animatedFromViews;
        }
    }
    return self;
}

- (instancetype)initWithDataSource:(id<KKMediaBrowserDataSource>)dataSource initialIndex:(NSUInteger)index {
    self = [self init];
    if (self) {
        _dataSource = dataSource;
        _currentPageIndex = index;
    }
    return self;
}

- (void)_initialisation {
    
    // Defaults
    NSNumber *isVCBasedStatusBarAppearanceNum = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
    if (isVCBasedStatusBarAppearanceNum) {
        _isVCBasedStatusBarAppearance = isVCBasedStatusBarAppearanceNum.boolValue;
    } else {
        _isVCBasedStatusBarAppearance = YES; // default
    }
    self.hidesBottomBarWhenPushed = YES;
    _hasBelongedToViewController = NO;
    _mediaCount = NSNotFound;
    _currentPageIndex = 0;
    _previousPageIndex = NSNotFound;
    _zoomMediaToFill = YES;
    _rotating = NO;
    _viewIsActive = NO;
    _initialStatusBarHidden = YES;
    _showVideoControl = YES;
    _delayToHideElements = 5;
    _didSavePreviousStateOfNavBar = NO;
    _backgroundColor = [UIColor blackColor];
    _mediaArray = [NSMutableArray array];
    _applicationWindow = [[UIApplication sharedApplication] keyWindow];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.modalPresentationCapturesStatusBarAppearance = YES;
}

- (void)dealloc {
    [self releaseAllUnderlyingPhotos:NO];
}

- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent {
    NSArray *copy = [_mediaArray copy];
    for (id p in copy) {
        if (p != [NSNull null]) {
            if (preserveCurrent && p == [self mediaAtIndex:self.currentIndex]) {
                continue;
            }
            [p unloadUnderlyingData];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [self releaseAllUnderlyingPhotos:YES];
    [super didReceiveMemoryWarning];
}

#pragma mark - View Loading

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // View
    self.view.backgroundColor = _backgroundColor;
    self.view.clipsToBounds = YES;
    
    // Setup collection view
    [self.view addSubview:self.collectionView];
    
    // Setup supplementary view
    [self setupSupplementaryView];
    
    // Update
    [self reloadData];
    
    // Gesture
    [self setupGesture];
    
    if (!self.isPresented) {
        UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        NSString *backButtonTitle = previousViewController.navigationItem.backBarButtonItem ? previousViewController.navigationItem.backBarButtonItem.title : previousViewController.title;
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:backButtonTitle style:UIBarButtonItemStylePlain target:nil action:nil];
        // Appearance
        [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsCompact];
        [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
        [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsCompact];
        [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
        [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
        _previousViewControllerBackButton = previousViewController.navigationItem.backBarButtonItem;
        previousViewController.navigationItem.backBarButtonItem = newBackButton;
    }
}

- (void)setupSupplementaryView {
    if ([self.dataSource respondsToSelector:@selector(supplementaryViewsForMediaBrowser:)]) {
        _supplementaryViews = [self.dataSource supplementaryViewsForMediaBrowser:self];
        [_supplementaryViews enumerateObjectsUsingBlock:^(__kindof UIView<KKMediaSupplementaryViewProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.view addSubview:obj];
        }];
    }
}

- (void)setupGesture {
    [self.view addGestureRecognizer:self.singleTapGesture];
    [self.view addGestureRecognizer:self.doubleTapGesture];
    [self.singleTapGesture requireGestureRecognizerToFail:self.doubleTapGesture];
    [self.view addGestureRecognizer:self.longPressGesture];
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([_delegate respondsToSelector:@selector(willAppearMediaBrowser:)]) {
        [_delegate willAppearMediaBrowser:self];
    }
    
    // Status bar
    if (!_viewHasAppearedInitially) {
        _leaveStatusBarAlone = [self presentingViewControllerPrefersStatusBarHidden];
        if (CGRectEqualToRect([[UIApplication sharedApplication] statusBarFrame], CGRectZero)) {
            _leaveStatusBarAlone = YES;
        }
    }
    // Set style
    if (!_leaveStatusBarAlone && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
    }
    
    // Navigation bar appearance
    if (!_viewIsActive && [self.navigationController.viewControllers objectAtIndex:0] != self) {
        [self storePreviousNavBarAppearance];
    }
    [self setNavBarAppearance:animated];
    
    if (self.isPresented && !_viewHasAppearedInitially) {
        [self performPresentAnimation];
    }
    
    // Layout
    [self.view setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setControlsHidden:_initialStatusBarHidden animated:NO permanent:YES];
    _viewIsActive = YES;
    _viewHasAppearedInitially = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    
    if ((self.isPresented && self.navigationController.isBeingDismissed) ||
        ([self.navigationController.viewControllers objectAtIndex:0] != self && ![self.navigationController.viewControllers containsObject:self])) {
        
        // State
        _viewIsActive = NO;
        
        // Bar state / appearance
        [self restorePreviousNavBarAppearance:animated];
    }
    
    // Controls
    [self.navigationController.navigationBar.layer removeAllAnimations]; // Stop all animations on nav bar
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self setControlsHidden:NO animated:NO permanent:YES];
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    // Status bar
    if (!_leaveStatusBarAlone && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle animated:animated];
    }

    // Super
    [super viewWillDisappear:animated];

}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent && _hasBelongedToViewController) {
        [NSException raise:@"KKMediaBrowser Instance Reuse" format:@"KKMediaBrowser instances cannot be reused."];
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (!parent) _hasBelongedToViewController = YES;
}

#pragma mark - Rorate

- (BOOL)shouldAutorotate {
    if (_viewIsActive) {
        return YES;
    }
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    _rotating = YES;
    CGFloat duration = [coordinator transitionDuration];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _rotating = NO;
    });
}

#pragma mark - Nav Bar Appearance

- (void)setNavBarAppearance:(BOOL)animated {
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.tintColor = [UIColor whiteColor];
    navBar.barTintColor = nil;
    navBar.shadowImage = nil;
    navBar.translucent = YES;
    navBar.barStyle = UIBarStyleBlackTranslucent;
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];
}

- (void)storePreviousNavBarAppearance {
    _didSavePreviousStateOfNavBar = YES;
    _previousNavBarBarTintColor = self.navigationController.navigationBar.barTintColor;
    _previousNavBarTranslucent = self.navigationController.navigationBar.translucent;
    _previousNavBarTintColor = self.navigationController.navigationBar.tintColor;
    _previousNavBarHidden = self.navigationController.navigationBarHidden;
    _previousNavBarStyle = self.navigationController.navigationBar.barStyle;
    _previousNavigationBarBackgroundImageDefault = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
    _previousNavigationBarBackgroundImageLandscapePhone = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsCompact];
    if (!self.isPresented) {
        UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        _previousViewControllerBackButton = previousViewController.navigationItem.backBarButtonItem; // remember previous
    }
}

- (void)restorePreviousNavBarAppearance:(BOOL)animated {
    if (_didSavePreviousStateOfNavBar) {
        [self.navigationController setNavigationBarHidden:_previousNavBarHidden animated:animated];
        UINavigationBar *navBar = self.navigationController.navigationBar;
        navBar.tintColor = _previousNavBarTintColor;
        navBar.translucent = _previousNavBarTranslucent;
        navBar.barTintColor = _previousNavBarBarTintColor;
        navBar.barStyle = _previousNavBarStyle;
        [navBar setBackgroundImage:_previousNavigationBarBackgroundImageDefault forBarMetrics:UIBarMetricsDefault];
        [navBar setBackgroundImage:_previousNavigationBarBackgroundImageLandscapePhone forBarMetrics:UIBarMetricsCompact];
        // Restore back button if we need to
        if (_previousViewControllerBackButton) {
            UIViewController *previousViewController = [self.navigationController topViewController]; // We've disappeared so previous is now top
            previousViewController.navigationItem.backBarButtonItem = _previousViewControllerBackButton;
            _previousViewControllerBackButton = nil;
        }
    }
}

#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _collectionViewLayout.itemSize = CGSizeMake(self.view.width + 2 * kMediaCellHorizontalPadding, self.view.height);
    _collectionViewLayout.minimumInteritemSpacing = 0;
    _collectionViewLayout.minimumLineSpacing = 0;
    _collectionView.frame = CGRectMake(-kMediaCellHorizontalPadding, 0, self.view.width + 2 * kMediaCellHorizontalPadding, self.view.height);
    [_collectionView setCollectionViewLayout:_collectionViewLayout];
    NSIndexPath *path = [NSIndexPath indexPathForRow:_currentPageIndex inSection:0];
    [_collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    [self layoutSupplementaryViewFrame];
}

- (void)layoutSupplementaryViewFrame {
    if (self.supplementaryViews.count > 0) {
        CGRect frame = [self frameForPageAtIndex:_currentPageIndex];
        [self.supplementaryViews enumerateObjectsUsingBlock:^(__kindof UIView<KKMediaSupplementaryViewProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj layoutSupplementaryViewThatFrame:frame];
        }];
    }
}

#pragma mark - Status Bar

- (BOOL)presentingViewControllerPrefersStatusBarHidden {
    UIViewController *presenting = self.presentingViewController;
    if (presenting) {
        if ([presenting isKindOfClass:[UINavigationController class]]) {
            presenting = [(UINavigationController *)presenting topViewController];
        }
    } else {
        if (self.navigationController && self.navigationController.viewControllers.count > 1) {
            presenting = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        }
    }
    if (presenting) {
        return [presenting prefersStatusBarHidden];
    } else {
        return NO;
    }
}


- (BOOL)prefersStatusBarHidden {
    if (!_leaveStatusBarAlone) {
        return _statusBarShouldBeHidden;
    } else {
        return [self presentingViewControllerPrefersStatusBarHidden];
    }
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return  UIStatusBarStyleDefault;
}

#pragma mark - Data

- (void)reloadData {
    // Reset
    _mediaCount = NSNotFound;
    
    // Get data
    NSUInteger numberOfMediaArray = [self numberOfMediaArray];
    [self releaseAllUnderlyingPhotos:YES];
    [_mediaArray removeAllObjects];
    for (int i = 0; i < numberOfMediaArray; i++) {
        [_mediaArray addObject:[NSNull null]];
    }
    
    // Update current page index
    if (numberOfMediaArray > 0) {
        _currentPageIndex = MAX(0, MIN(_currentPageIndex, numberOfMediaArray - 1));
    } else {
        _currentPageIndex = 0;
    }
    
    [_collectionView reloadData];
    NSIndexPath *path = [NSIndexPath indexPathForRow:_currentPageIndex inSection:0];
    [_collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    
    if ([self.delegate respondsToSelector:@selector(mediaBrowser:didShowMediaAtIndex:)]) {
        [self.delegate mediaBrowser:self didShowMediaAtIndex:_currentPageIndex];
    }
}

- (NSUInteger)numberOfMediaArray {
    if (_mediaCount == NSNotFound) {
        if ([_dataSource respondsToSelector:@selector(numberOfMediaInMediaBrowser:)]) {
            _mediaCount = [_dataSource numberOfMediaInMediaBrowser:self];
        } else if (_fixedMediaArray) {
            _mediaCount = _fixedMediaArray.count;
        }
    }
    if (_mediaCount == NSNotFound) _mediaCount = 0;
    return _mediaCount;
}

- (id<KKMediaProtocol>)mediaAtIndex:(NSUInteger)index {
    id <KKMediaProtocol> media = nil;
    if (index < _mediaArray.count) {
        if ([_mediaArray objectAtIndex:index] == [NSNull null]) {
            if ([_dataSource respondsToSelector:@selector(mediaBrowser:mediaAtIndex:)]) {
                media = [_dataSource mediaBrowser:self mediaAtIndex:index];
            } else if (_fixedMediaArray && index < _fixedMediaArray.count) {
                media = [_fixedMediaArray objectAtIndex:index];
            }
            if (media) [_mediaArray replaceObjectAtIndex:index withObject:media];
        } else {
            media = [_mediaArray objectAtIndex:index];
        }
    }
    return media;
}

- (NSArray *)viewStateArray {
    NSArray *array = _viewStates;
    if ([_dataSource respondsToSelector:@selector(animatedFromViewsForMediaBrowser:)]) {
        array = [_dataSource animatedFromViewsForMediaBrowser:self];
    }
    return array;
}

- (KKMediaFromViewState *)viewStateForMedia:(id<KKMediaProtocol>)media {
    __block KKMediaFromViewState *viewState = nil;
    if (!media) {
        return viewState;
    }
    
    NSArray *viewStateArray = [self viewStateArray];
    if (!viewStateArray) {
        return viewState;
    }
    
    [viewStateArray enumerateObjectsUsingBlock:^(KKMediaFromViewState *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.media isEqual:media]) {
            viewState = obj;
            *stop = YES;
        }
    }];
    
    return viewState;
}

- (void)loadAdjacentMeidaIfNecessary:(NSUInteger)pageIndex {
    if (pageIndex > 0) {
        // Preload index - 1
        id <KKMediaProtocol> photo = [self mediaAtIndex:pageIndex-1];
        if (![photo underlyingData]) {
            [photo loadUnderlyingDataAndNotify];
        }
    }
    if (pageIndex < [self numberOfMediaArray] - 1) {
        // Preload index + 1
        id <KKMediaProtocol> photo = [self mediaAtIndex:pageIndex+1];
        if (![photo underlyingData]) {
            [photo loadUnderlyingDataAndNotify];
        }
    }
}


- (void)setCurrentMediaIndex:(NSUInteger)index {
    // Validate
    NSUInteger photoCount = [self numberOfMediaArray];
    if (photoCount == 0) {
        index = 0;
    } else {
        if (index >= photoCount)
            index = [self numberOfMediaArray]-1;
    }
    _currentPageIndex = index;
    if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index animated:NO];
    }
}

- (KKMediaDisplayView *)pageDisplayingMedia:(id<KKMediaProtocol>)media {
    if (media.mediaType == KKMediaTypeVideo) {
        return nil;
    }
    KKMediaDisplayView *thePage = nil;
    for (KKMediaCell *cell in self.collectionView.visibleCells) {
        if (cell.media == media) {
            if ([cell isKindOfClass:KKMediaPhotoCell.class]) {
                thePage = [(KKMediaPhotoCell *)cell displayView];
            }
            break;
        }
    }
    return thePage;
}

- (KKMediaCell *)currentMediaCell {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_currentPageIndex inSection:0];
    KKMediaCell *cell = (KKMediaCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    return cell;
}

#pragma mark - Animation

- (void)performPresentAnimation {
    
    id<KKMediaProtocol> media = [self mediaAtIndex:_currentPageIndex];
    if (!media) {
        return;
    }
    KKMediaFromViewState *viewState = [self viewStateForMedia:media];
    if (!viewState) {
        return;
    }
    
    UIImage *imageFromView;
    if ([viewState.media respondsToSelector:@selector(placeholderImage)] && viewState.media.placeholderImage) {
        imageFromView = viewState.media.placeholderImage;
    }
    
    if (!imageFromView || ![imageFromView isKindOfClass:UIImage.class]) {
        return;
    }
    
    CGRect senderViewOriginalFrame = [viewState.senderViewForAnimation.superview convertRect:viewState.senderViewForAnimation.frame toView:self.view];
    
    UIView *fadeView = [[UIView alloc] initWithFrame:_applicationWindow.bounds];
    fadeView.backgroundColor = self.backgroundColor;
    [_applicationWindow addSubview:fadeView];
    
    UIImageView *resizableImageView = [[UIImageView alloc] initWithImage:imageFromView];
    resizableImageView.frame = senderViewOriginalFrame;
    resizableImageView.clipsToBounds = YES;
    resizableImageView.contentMode = viewState.senderViewForAnimation ? viewState.senderViewForAnimation.contentMode : UIViewContentModeScaleAspectFill;
    resizableImageView.backgroundColor = [UIColor clearColor];
    [_applicationWindow addSubview:resizableImageView];
    
    self.view.hidden = YES;
    void (^completion)(void) = ^() {
        self.view.hidden = NO;
        [resizableImageView removeFromSuperview];
        [fadeView removeFromSuperview];
        
        [self autoPlayVideo];
    };
    
    BOOL isNeedToZoom = _zoomMediaToFill;
    if (media.mediaType == KKMediaTypeGif) {
        isNeedToZoom = NO;
    } else if (media.mediaType == KKMediaTypeVideo) {
        isNeedToZoom = YES;
    }
    
    CGRect finalImageViewFrame = [self animationFrameForImage:imageFromView isNeedToZoom:isNeedToZoom];
    [UIView animateWithDuration:0.25 animations:^{
        resizableImageView.layer.frame = finalImageViewFrame;
    } completion:^(BOOL finished) {
        completion();
    }];
}

- (void)performCloseAnimation {
    
    if ([_delegate respondsToSelector:@selector(willDisappearMediaBrowser:)]) {
        [_delegate willDisappearMediaBrowser:self];
    }
    
    UIDeviceOrientation orientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
    BOOL isLandscape = (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight);
    if (isLandscape) {
        [self prepareForCloseMediaBrowser];
        [self dismissMediaBrowserAnimated:YES];
        return;
    }
    
    id<KKMediaProtocol> media = [self mediaAtIndex:_currentPageIndex];
    if (!media) {
        [self prepareForCloseMediaBrowser];
        [self dismissMediaBrowserAnimated:YES];
        return;
    }
    KKMediaFromViewState *viewState = [self viewStateForMedia:media];
    if (!viewState) {
        [self prepareForCloseMediaBrowser];
        [self dismissMediaBrowserAnimated:YES];
        return;
    }
    
    if (media.dataStatus == KKMediaDataStatusLoading && media.mediaType != KKMediaTypeVideo) {
        [self prepareForCloseMediaBrowser];
        [self dismissMediaBrowserAnimated:YES];
        return;
    }
    
    UIImage *imageFromView;
    if (self.closeImageFromSender) {
        imageFromView = [self getImageFromView:viewState.senderViewForAnimation];
    } else {
        imageFromView = viewState.media.placeholderImage;
    }
    
    if (!imageFromView || ![imageFromView isKindOfClass:UIImage.class]) {
        [self prepareForCloseMediaBrowser];
        [self dismissMediaBrowserAnimated:YES];
        return;
    }
    
    BOOL isNeedToZoom = _zoomMediaToFill;
    if (media.mediaType == KKMediaTypeGif) {
        isNeedToZoom = NO;
    } else if (media.mediaType == KKMediaTypeVideo) {
        isNeedToZoom = YES;
    }
    CGRect imageViewFrame = [self animationFrameForImage:imageFromView isNeedToZoom:isNeedToZoom];
    
    UIImageView *resizableImageView = [[UIImageView alloc] initWithImage:imageFromView];
    resizableImageView.frame = imageViewFrame;
    resizableImageView.contentMode = viewState.senderViewForAnimation ? viewState.senderViewForAnimation.contentMode : UIViewContentModeScaleAspectFill;
    resizableImageView.backgroundColor = [UIColor clearColor];
    resizableImageView.clipsToBounds = YES;
    [_applicationWindow addSubview:resizableImageView];
    
    if (_scaleImageHidden) {
        viewState.senderViewForAnimation.hidden = YES;
    }
    
    void (^completion)(void) = ^() {
        viewState.senderViewForAnimation.hidden = NO;
        [resizableImageView removeFromSuperview];
    };
    
    [self prepareForCloseMediaBrowser];
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    if ([_delegate respondsToSelector:@selector(mediaBrowser:willDismissAtPageIndex:)])
        [_delegate mediaBrowser:self willDismissAtPageIndex:_currentPageIndex];
    
    [self dismissViewControllerAnimated:NO completion:^{
        if ([_delegate respondsToSelector:@selector(mediaBrowser:didDismissAtPageIndex:)])
            [_delegate mediaBrowser:self didDismissAtPageIndex:_currentPageIndex];
        
        CGRect senderViewOriginalFrame = [viewState.senderViewForAnimation.superview convertRect:viewState.senderViewForAnimation.frame toView:_applicationWindow];
        
        [UIView animateWithDuration:0.25 animations:^{
            resizableImageView.layer.frame = senderViewOriginalFrame;
        } completion:^(BOOL finished) {
            completion();
        }];
        
    }];
}

- (CGRect)animationFrameForImage:(UIImage *)image isNeedToZoom:(BOOL)isNeedToZoom {
    if (!image) {
        return CGRectZero;
    }
    
    CGRect animationFrame = CGRectZero;
    
    CGSize imageSize = image.size;
    CGSize boundsSize = CGSizeMake(CGRectGetWidth(_applicationWindow.bounds), CGRectGetHeight(_applicationWindow.bounds));
    
    animationFrame = [KKMediaBrowser convertImageSize:imageSize toContainerSize:boundsSize isNeedToZoom:isNeedToZoom];
    
    return animationFrame;
}

#pragma mark - General

- (void)dismissBrowserAnimated:(BOOL)animated {
    if (animated) {
        [self performCloseAnimation];
    } else {
        [self prepareForCloseMediaBrowser];
        [self dismissMediaBrowserAnimated:NO];
    }
}

- (void)prepareForCloseMediaBrowser {
    [self setControlsHidden:[self presentingViewControllerPrefersStatusBarHidden] animated:NO permanent:NO];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)dismissMediaBrowserAnimated:(BOOL)animated {
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [KKMediaBrowser setDeviceOrientation:UIInterfaceOrientationPortrait];
    
    if ([_delegate respondsToSelector:@selector(mediaBrowser:willDismissAtPageIndex:)])
        [_delegate mediaBrowser:self willDismissAtPageIndex:_currentPageIndex];
    
    [self dismissViewControllerAnimated:animated completion:^{
        if ([_delegate respondsToSelector:@selector(mediaBrowser:didDismissAtPageIndex:)])
            [_delegate mediaBrowser:self didDismissAtPageIndex:_currentPageIndex];
    }];
}

+ (void)setDeviceOrientation:(UIInterfaceOrientation)orientation {
    if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        return;
    }
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector  = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        [invocation setArgument:&orientation atIndex:2];
        [invocation invoke];
    }
}

- (UIImage*)getImageFromView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 2);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)autoPlayVideo {
    KKMediaCell *cell = [self currentMediaCell];
    if ([cell isKindOfClass:[KKMediaVideoCell class]]) {
        KKMediaVideoCell *videoCell = (KKMediaVideoCell *)cell;
        [videoCell startPlay];
    }
}

+ (CGRect)convertImageSize:(CGSize)imageSize toContainerSize:(CGSize)containerSize isNeedToZoom:(BOOL)isNeedToZoom {
    
    if (CGSizeEqualToSize(imageSize, CGSizeZero) || CGSizeEqualToSize(containerSize, CGSizeZero)) {
        return CGRectZero;
    }
    
    CGRect convertFrame = CGRectZero;
    
    CGFloat imageAR = imageSize.width / imageSize.height;
    CGFloat xScale = containerSize.width / imageSize.width;
    CGFloat yScale = containerSize.height / imageSize.height;
    
    if (isNeedToZoom) { // 图片需填充整个屏幕
        
        if (xScale > yScale) { //Y轴方向填充
            convertFrame.size = CGSizeMake(containerSize.height * imageAR, containerSize.height);
        } else {  //X轴方向填充
            convertFrame.size = CGSizeMake(containerSize.width, containerSize.width / imageAR);
        }
        
        if (imageAR < 0.3) { // 高度很高的长图
            convertFrame.size = CGSizeMake(containerSize.width, containerSize.width / imageAR);
        }
        
    } else { // 小图不填充，特别大图不超过屏幕尺寸
        
        if (xScale >= 1 && yScale >= 1) { //不缩放
            convertFrame.size = imageSize;
        } else { // 缩小至整个屏幕内显示
            if (xScale > yScale) { //Y轴方向填充
                convertFrame.size = CGSizeMake(containerSize.height * imageAR, containerSize.height);
            } else {  //X轴方向填充
                convertFrame.size = CGSizeMake(containerSize.width, containerSize.width / imageAR);
            }
        }
    }
    
    CGFloat originX = roundf((containerSize.width - convertFrame.size.width) / 2.0f);
    CGFloat originY = roundf((containerSize.height - convertFrame.size.height) / 2.0f);
    convertFrame.origin.x = originX < 0 ? 0 : originX;
    convertFrame.origin.y = originY < 0 ? 0 : originY;
    
    return convertFrame;
}

#pragma mark - Frame Calculations

- (CGRect)frameForPagingCollectionView {
    CGRect frame = [UIScreen mainScreen].bounds;
    frame.origin.x -= kMediaCellHorizontalPadding;
    frame.size.width += (2 * kMediaCellHorizontalPadding);
    return CGRectIntegral(frame);
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    CGRect bounds = _collectionView.bounds;
    if (KKIsiPhoneX) {
        bounds.size.height -= KKiPhoneXBottomHeight;
    }
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * kMediaCellHorizontalPadding);
    pageFrame.origin.x = (bounds.size.width * index) + kMediaCellHorizontalPadding;
    return CGRectIntegral(pageFrame);
}


#pragma mark - Control Hiding / Showing

// If permanent then we don't set timers to hide again
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {

    // Animations & positions
    CGFloat animationDuration = (animated ? 0.35 : 0);
    
    // Status bar
    if (!_leaveStatusBarAlone) {
        
        // Hide status bar
        if (!_isVCBasedStatusBarAppearance) {
            
            // Non-view controller based
            [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
            
        } else {
            
            // View controller based so animate away
            _statusBarShouldBeHidden = hidden;
            [UIView animateWithDuration:animationDuration animations:^(void) {
                [self setNeedsStatusBarAppearanceUpdate];
            } completion:^(BOOL finished) {}];
            
        }
        
    }
    
    // Toolbar, nav bar and captions
    if ([self areControlsHidden] && !hidden && animated) {
        
        // Toolbar
        
    }
    [UIView animateWithDuration:animationDuration animations:^(void) {
        
        CGFloat alpha = hidden ? 0 : 1;
        
        _isControlHidden = hidden;
        
        // Nav bar slides up on it's own on iOS 7+
        [self.navigationController.navigationBar setAlpha:alpha];
        
        // Toolbar
       
        
        // Captions
        
    } completion:^(BOOL finished) {}];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)areControlsHidden {
    return _isControlHidden;
}

- (void)handleSingleTap {
    if (self.isPresented) {
        if (!_showVideoControl) {
            [self performCloseAnimation];
            return;
        }
        KKMediaCell *cell = [self currentMediaCell];
        if ([cell isKindOfClass:[KKMediaVideoCell class]]) {
            [(KKMediaVideoCell *)cell toggleControls];
        } else {
            [self performCloseAnimation];
        }
    } else {
        [self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO];
    }
}

- (void)longPressMenuShow {
    
    id<KKMediaProtocol> media = [self mediaAtIndex:_currentPageIndex];
    
    if (!media) {
        return;
    }
    
    NSMutableArray *actionArray = [NSMutableArray array];
    if ([self.dataSource respondsToSelector:@selector(actionArrayForMedia:withStatus:)]) {
        [actionArray addObjectsFromArray:[self.dataSource actionArrayForMedia:media withStatus:media.dataStatus]];
    }
    
    if (actionArray.count == 0) {
        return;
    }
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    self.actionSheet = actionSheet;
    
    [actionArray enumerateObjectsUsingBlock:^(UIAlertAction *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [actionSheet addAction:obj];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [actionSheet addAction:cancel];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark - Navigation


- (void)updateNavigation {
    
    // Title
   
    
}

- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated {
    
    // Change page
    if (index < [self numberOfMediaArray]) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
        [self.collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionNone animated:animated];
        [self updateNavigation];
    }
}

- (void)gotoPreviousPage {
    [self showPreviousMediaAnimated:NO];
}
- (void)gotoNextPage {
    [self showNextMediaAnimated:NO];
}

- (void)showPreviousMediaAnimated:(BOOL)animated {
    [self jumpToPageAtIndex:_currentPageIndex-1 animated:animated];
}

- (void)showNextMediaAnimated:(BOOL)animated {
    [self jumpToPageAtIndex:_currentPageIndex+1 animated:animated];
}

#pragma mark - Gesture

- (void)longPressGestureRecognized:(UILongPressGestureRecognizer *)sender {
    if ([sender isKindOfClass:UILongPressGestureRecognizer.class]
        && sender.state == UIGestureRecognizerStateBegan) {
        [self longPressMenuShow];
    }
}

- (void)singleTapGestureRecognized:(UITapGestureRecognizer *)sender {
    if (_rotating) return;
    [self handleSingleTap];
}

- (void)doubleTapGestureRecognized:(UITapGestureRecognizer *)sender {
    
    id<KKMediaProtocol> media = [self mediaAtIndex:_currentPageIndex];
    KKMediaDisplayView *page = [self pageDisplayingMedia:media];
    
    if (media.dataStatus != KKMediaDataStatusSuccess || !page) {
        return;
    }
    
    CGPoint point = [sender locationInView:page];
    if (CGRectContainsPoint(page.imageView.frame, point)) {
        point = [sender locationInView:page.imageView];
    } else {
        CGFloat touchX = [sender locationInView:page].x;
        CGFloat touchY = [sender locationInView:page].y;
        touchX *= 1/page.scrollView.zoomScale;
        touchY *= 1/page.scrollView.zoomScale;
        touchX += page.scrollView.contentOffset.x;
        touchY += page.scrollView.contentOffset.y;
        point = CGPointMake(touchX, touchY);
    }
    [page handleDoubleTap:point];
}

#pragma mark - KKMedaiCellDelegate

- (void)mediaCellDidClose:(KKMediaCell *)cell {
    [self performCloseAnimation];
}

- (void)mediaCellDidMenu:(KKMediaCell *)cell {
    [self longPressMenuShow];
}

- (void)mediaCell:(id)mediaCell didLoadingEndMedia:(id<KKMediaProtocol>)media {
    if ([self.delegate respondsToSelector:@selector(mediaBrowser:didLoadingEndMedia:)]) {
        [self.delegate mediaBrowser:self didLoadingEndMedia:media];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self numberOfMediaArray];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    KKMediaCell *cell;
    id<KKMediaProtocol> media = [self mediaAtIndex:indexPath.row];
    if (media.mediaType == KKMediaTypeGif) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:kMediaGifCellIdentifier forIndexPath:indexPath];
    } else if (media.mediaType == KKMediaTypeVideo) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:kMediaVideoCellIdentifier forIndexPath:indexPath];
        KKMediaVideoCell *videoCell = (KKMediaVideoCell *)cell;
        videoCell.showControlView = self.showVideoControl;
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:kMediaPhotoCellIdentifier forIndexPath:indexPath];
    }
    cell.media = media;
    cell.delegate = self;
    cell.zoomMediaToFill = self.zoomMediaToFill;
    [self loadAdjacentMeidaIfNecessary:indexPath.row];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(mediaBrowser:willShowMediaAtIndex:)]) {
        [self.delegate mediaBrowser:self willShowMediaAtIndex:indexPath.row];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.delegate respondsToSelector:@selector(mediaBrowser:didShowMediaAtIndex:)]) {
        [self.delegate mediaBrowser:self didShowMediaAtIndex:_currentPageIndex];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (_rotating) {
        return NO;
    }
    return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // Checks
    if (!_viewIsActive || _rotating) return;
    
    CGFloat offSetWidth = scrollView.contentOffset.x;
    offSetWidth = offSetWidth +  ((self.view.bounds.size.width + kMediaCellHorizontalPadding * 2) * 0.5);
    
    NSInteger currentIndex = offSetWidth / (self.view.bounds.size.width + kMediaCellHorizontalPadding * 2);
    
    if (currentIndex < 0) currentIndex = 0;
    if (currentIndex > [self numberOfMediaArray] - 1) currentIndex = [self numberOfMediaArray] - 1;
    
    if (currentIndex != _currentPageIndex) {
        KKMediaCell *cell = [self currentMediaCell];
        [cell mediaBrowserCollectionViewDidScroll];
    }
    
    _currentPageIndex = currentIndex;
}

#pragma mark - Getter 

- (BOOL)isPresented {
    
    if (!self.navigationController) {
        return YES;
    }
    
    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
        return YES;
    } else {
        return NO;
    }
}

- (NSUInteger)currentIndex {
    return _currentPageIndex;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        _collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[KKMediaCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_collectionViewLayout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.pagingEnabled = YES;
        _collectionView.scrollsToTop = NO;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[KKMediaPhotoCell class] forCellWithReuseIdentifier:kMediaPhotoCellIdentifier];
        [_collectionView registerClass:[KKMediaGifCell class] forCellWithReuseIdentifier:kMediaGifCellIdentifier];
        [_collectionView registerClass:[KKMediaVideoCell class] forCellWithReuseIdentifier:kMediaVideoCellIdentifier];
    }
    return _collectionView;
}

- (UILongPressGestureRecognizer *)longPressGesture {
    if (!_longPressGesture) {
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)];
    }
    return _longPressGesture;
}

- (UITapGestureRecognizer *)singleTapGesture {
    if (!_singleTapGesture) {
        _singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureRecognized:)];
        _singleTapGesture.numberOfTapsRequired = 1;
        _singleTapGesture.delegate = self;
    }
    return _singleTapGesture;
}

- (UITapGestureRecognizer *)doubleTapGesture {
    if (!_doubleTapGesture) {
        _doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestureRecognized:)];
        _doubleTapGesture.numberOfTapsRequired = 2;
        _doubleTapGesture.numberOfTouchesRequired = 1;
    }
    return _doubleTapGesture;
}

@end


@implementation KKMediaFromViewState

@end


@implementation KKMediaCollectionView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    UIView *view = [super hitTest:point withEvent:event];
    
    if ([view isKindOfClass:[UISlider class]]) {
        //如果响应view是UISlider,则scrollview禁止滑动
        self.scrollEnabled = NO;
    } else {   //如果不是,则恢复滑动
        self.scrollEnabled = YES;
    }
    return view;
}

@end
