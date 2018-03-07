//
//  KKMediaBrowser.h
//  KKPhotoBrowser
//
//  Created by coze on 2017/5/26.
//  Copyright © 2017年 kook.sdk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKMediaProtocol.h"

/**
 此类来源于 Michael Waterfall 的优秀开源项目：MWPhotoBrowser
 github链接：https://github.com/mwaterfall/MWPhotoBrowser
 感谢 Michael Waterfall 的优秀代码
 */

@class KKMediaBrowser, KKMediaFromViewState;

@protocol KKMediaBrowserDataSource <NSObject>

@required

- (NSUInteger)numberOfMediaInMediaBrowser:(KKMediaBrowser *)mediaBrowser;
- (id<KKMediaProtocol>)mediaBrowser:(KKMediaBrowser *)mediaBrowser mediaAtIndex:(NSUInteger)index;

@optional

- (NSArray <__kindof KKMediaFromViewState*>*)animatedFromViewsForMediaBrowser:(KKMediaBrowser *)mediaBrowser;
- (NSArray <__kindof UIAlertAction*>*)actionArrayForMedia:(id<KKMediaProtocol>)media withStatus:(KKMediaDataStatus)status;

- (NSArray <__kindof UIView<KKMediaSupplementaryViewProtocol>*> *)supplementaryViewsForMediaBrowser:(KKMediaBrowser *)mediaBrowser;

@end

@protocol KKMediaBrowserDelegate <NSObject>

@optional

- (void)willAppearMediaBrowser:(KKMediaBrowser *)mediaBrowser;
- (void)willDisappearMediaBrowser:(KKMediaBrowser *)mediaBrowser;
- (void)mediaBrowser:(KKMediaBrowser *)mediaBrowser willShowMediaAtIndex:(NSUInteger)index;
- (void)mediaBrowser:(KKMediaBrowser *)mediaBrowser didShowMediaAtIndex:(NSUInteger)index;
- (void)mediaBrowser:(KKMediaBrowser *)mediaBrowser willDismissAtPageIndex:(NSUInteger)index;
- (void)mediaBrowser:(KKMediaBrowser *)mediaBrowser didDismissAtPageIndex:(NSUInteger)index;
- (void)mediaBrowser:(KKMediaBrowser *)mediaBrowser didLoadingEndMedia:(id<KKMediaProtocol>)media;

@end

@interface KKMediaBrowser : UIViewController <UIScrollViewDelegate>

// Properties
@property (nonatomic, weak) id<KKMediaBrowserDataSource> dataSource;
@property (nonatomic, weak) id<KKMediaBrowserDelegate> delegate;

// View customization
@property (nonatomic, assign) BOOL initialStatusBarHidden;
@property (nonatomic, assign) BOOL zoomMediaToFill;
@property (nonatomic, assign) BOOL scaleImageHidden;
@property (nonatomic, assign) BOOL showVideoControl;
@property (nonatomic, assign) BOOL closeImageFromSender;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, assign) NSUInteger delayToHideElements;

// Init
- (instancetype)initWithMediaArray:(NSArray *)mediaArray;
- (instancetype)initWithDataSource:(id<KKMediaBrowserDataSource>)dataSource;

- (instancetype)initWithMediaArray:(NSArray *)mediaArray initialIndex:(NSUInteger)index animatedFromViews:(NSArray *)animatedFromViews;
- (instancetype)initWithDataSource:(id<KKMediaBrowserDataSource>)dataSource initialIndex:(NSUInteger)index;

// Data
- (void)reloadData;
- (NSUInteger)currentIndex;
- (void)setCurrentMediaIndex:(NSUInteger)index;
- (id<KKMediaProtocol>)mediaAtIndex:(NSUInteger)index;

// Navigation
- (void)showNextMediaAnimated:(BOOL)animated;
- (void)showPreviousMediaAnimated:(BOOL)animated;

- (void)dismissBrowserAnimated:(BOOL)animated;

+ (CGRect)convertImageSize:(CGSize)imageSize toContainerSize:(CGSize)containerSize isNeedToZoom:(BOOL)isNeedToZoom;

@end


@interface KKMediaFromViewState : NSObject

@property (nonatomic, strong) UIView *senderViewForAnimation;
@property (nonatomic, strong) id<KKMediaProtocol> media;

@end
