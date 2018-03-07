//
//  KKMediaPhotoCell.m
//  Kook
//
//  Created by coze on 2017/8/8.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import "KKMediaPhotoCell.h"
#import "KKView+Base.h"

@implementation KKMediaPhotoCell
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
    _displayView = [[KKMediaDisplayView alloc] init];
    [self addSubview:_displayView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _displayView.frame = self.bounds;
}

- (void)setMedia:(id<KKMediaProtocol>)media {
    [super setMedia:media];
    self.displayView.media = media;
    
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
    [self.displayView displayData];
}

- (void)setZoomMediaToFill:(BOOL)zoomMediaToFill {
    [super setZoomMediaToFill:zoomMediaToFill];
    _displayView.zoomMediaToFill = zoomMediaToFill;
}


@end
