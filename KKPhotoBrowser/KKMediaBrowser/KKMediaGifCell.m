//
//  KKMediaGifCell.m
//  Kook
//
//  Created by coze on 2017/8/8.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import "KKMediaGifCell.h"
#import "KKView+Base.h"
#import "KKMediaBrowser.h"
#import <YYWebImage.h>

@implementation KKMediaGifCell
#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _displayView = [[YYAnimatedImageView alloc] init];
    [self addSubview:_displayView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat originY = 0;
    CGFloat originX = kMediaCellHorizontalPadding;
    CGFloat height = self.height;
    CGFloat width = self.width-2*kMediaCellHorizontalPadding;
    
    if (_displayView.image) {
        CGSize containerSize = CGSizeMake(width, height);
        CGSize imageSize = CGSizeMake(_displayView.image.size.width * _displayView.image.scale, _displayView.image.size.height * _displayView.image.scale);
        
        CGRect imageViewFrame = [KKMediaBrowser convertImageSize:imageSize toContainerSize:containerSize isNeedToZoom:NO];
        imageViewFrame.origin.x += originX;
        imageViewFrame.origin.y += originY;
        
        _displayView.frame = imageViewFrame;
    }
}

- (void)setMedia:(id<KKMediaProtocol>)media {
    [super setMedia:media];
    
    if (media.underlyingData) {
        [self displayData];
    } else {
        [media loadUnderlyingDataAndNotify];
        
        id placeholderImg = nil;
        if ([media respondsToSelector:@selector(placeholderImage)]) {
            placeholderImg = media.placeholderImage;
        }
        if (placeholderImg) {
            [self showPlaceholderImage:placeholderImg];
        } else {
            [self hidePlaceholderImage];
        }
        [self showLoadingIndicator];
    }
}

- (void)displayData {
    [super displayData];
    
    _displayView.image = self.media.underlyingData;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
