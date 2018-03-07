//
//  KKMediaDisplayView.m
//  Kook
//
//  Created by coze on 2017/8/8.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import "KKMediaDisplayView.h"
#import "KKMediaCell.h"
#import "KKMediaBrowser.h"
#import "KKView+Base.h"
#import <YYWebImage.h>


@interface KKMediaDisplayView ()<UIScrollViewDelegate>

@end

@implementation KKMediaDisplayView

#pragma mark - Init

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _initialisation];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _initialisation];
    }
    return self;
}

- (void)_initialisation {
    
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.bouncesZoom = YES;
    _scrollView.multipleTouchEnabled = YES;
    _scrollView.delegate = self;
    _scrollView.scrollsToTop = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.delaysContentTouches = NO;
    _scrollView.canCancelContentTouches = YES;
    _scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    _scrollView.frame = CGRectMake(kMediaCellHorizontalPadding, 0, self.width - 2 * kMediaCellHorizontalPadding, self.height);
    [self addSubview:_scrollView];
    
    _imageContainerView = [[UIView alloc] init];
    _imageContainerView.clipsToBounds = YES;
    _imageContainerView.contentMode = UIViewContentModeScaleAspectFill;
    [_scrollView addSubview:_imageContainerView];
    
    _imageView = [[YYAnimatedImageView alloc] init];
    _imageView.backgroundColor = [UIColor clearColor];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [_imageContainerView addSubview:_imageView];
}

- (void)dealloc {
    if ([_media respondsToSelector:@selector(cancelAnyLoading)]) {
        [_media cancelAnyLoading];
    }
}

#pragma mark - Layout

- (void)layoutSubviews {
    
    // Super
    [super layoutSubviews];
    
    _scrollView.frame = CGRectMake(kMediaCellHorizontalPadding, 0, self.width - 2 * kMediaCellHorizontalPadding, self.height);
    
    [self recoverSubviews];
}

#pragma mark - Media


- (void)displayData {
    
    if (!_media) return;
    
    // Set image
    _imageView.image = self.media.underlyingData;
    _imageView.hidden = NO;
    
    [self recoverSubviews];
}


#pragma mark - Public

- (void)prepareForReuse {
    
    self.userInteractionEnabled = YES;
    _media = nil;
    _imageView.hidden = NO;
    _imageView.image = nil;
    
    // Reset
    _scrollView.maximumZoomScale = 1;
    _scrollView.minimumZoomScale = 1;
    _scrollView.zoomScale = 1;
    _scrollView.contentSize = CGSizeMake(0, 0);
}

#pragma mark - Private

- (BOOL)displayingImage {
    if (_media) {
        return (_media.mediaType == KKMediaTypePhoto);
    }
    return NO;
}

- (void)recoverSubviews {

    if (self.scrollView.zoomScale != 1.0) {
        self.scrollView.zoomScale = 1.0;
    }
    
    [self resizeSubviews];
    
    [self setMaxMinZoomScalesForCurrentBounds];
}

- (void)resizeSubviews {
    
    CGSize imageSize = CGSizeMake(_imageView.image.size.width * _imageView.image.scale, _imageView.image.size.height * _imageView.image.scale);
    
    CGSize boundsSize = CGSizeMake(self.scrollView.width, self.height);
    
    CGRect imageFrame = [KKMediaBrowser convertImageSize:imageSize toContainerSize:boundsSize isNeedToZoom:_zoomMediaToFill];
    _imageContainerView.frame = imageFrame;
    _scrollView.contentSize = imageFrame.size;
    
    [_scrollView scrollRectToVisible:self.bounds animated:NO];
    _imageView.frame = _imageContainerView.bounds;
}

- (void)setMaxMinZoomScalesForCurrentBounds {
    
    // Reset
    self.scrollView.maximumZoomScale = 2.5;
    self.scrollView.minimumZoomScale = 1;
    
    // Sizes
    CGSize boundsSize = self.scrollView.size;
    CGSize imageSize = _imageContainerView.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;
    CGFloat yScale = boundsSize.height / imageSize.height;
    CGFloat minScale = MIN(xScale, yScale);
    
    // Calculate Max
    CGFloat maxScale = [self doubleTapZoomScale] * 1.5;
    
    // Set min/max zoom
    self.scrollView.maximumZoomScale = maxScale;
    self.scrollView.minimumZoomScale = minScale;
    
    if (![self displayingImage]) {
        self.scrollView.maximumZoomScale = self.scrollView.zoomScale;
        self.scrollView.minimumZoomScale = self.scrollView.zoomScale;
    }
}

- (CGFloat)doubleTapZoomScale {
    CGFloat zoomScale = ((self.scrollView.maximumZoomScale + self.scrollView.minimumZoomScale) / 2);
    if (_imageContainerView) {
        CGSize boundsSize = _scrollView.size;
        CGSize imageSize = _imageContainerView.size;
        CGFloat xScale = boundsSize.width / imageSize.width;
        CGFloat yScale = boundsSize.height / imageSize.height;
        zoomScale = MAX(xScale, yScale);
        
        CGFloat defaultZoomScale = 1.0;
        if (zoomScale / defaultZoomScale <= 2) {
            zoomScale *= 2;
        }
    }
    return zoomScale;
}

- (void)resetImageCenter {
    CGFloat offsetX = (_scrollView.width > _scrollView.contentSize.width) ? ((_scrollView.width - _scrollView.contentSize.width) * 0.5) : 0.0;
    CGFloat offsetY = (_scrollView.height > _scrollView.contentSize.height) ? ((_scrollView.height - _scrollView.contentSize.height) * 0.5) : 0.0;
    self.imageContainerView.center = CGPointMake(_scrollView.contentSize.width * 0.5 + offsetX, _scrollView.contentSize.height * 0.5 + offsetY);
}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageContainerView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self resetImageCenter];
}

#pragma mark - Tap Detection

- (void)handleDoubleTap:(CGPoint)touchPoint {
    
    if (![self displayingImage]) return;
    
    CGFloat defaultZoomScale = 1.0;
    // Zoom
    if (self.scrollView.zoomScale != defaultZoomScale) {
        // Zoom out
        [self.scrollView setZoomScale:defaultZoomScale animated:YES];
    } else {
        
        // Zoom in to twice the size
        CGFloat newZoomScale = [self doubleTapZoomScale];
        CGFloat xsize = self.scrollView.bounds.size.width / newZoomScale;
        CGFloat ysize = self.scrollView.bounds.size.height / newZoomScale;
        [self.scrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
        
    }
}

@end
