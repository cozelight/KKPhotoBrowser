//
//  KKMediaCell.m
//  KKPhotoBrowser
//
//  Created by coze on 2017/6/2.
//  Copyright © 2017年 kook.sdk. All rights reserved.
//

#import "KKMediaCell.h"
#import "KKMediaBrowser.h"
#import "KKView+Base.h"
#import "KKMedia.h"
#import <DACircularProgressView.h>
#import <MMMaterialDesignSpinner.h>
#import <YYWebImage.h>


CGFloat kMediaCellHorizontalPadding = 10;

@interface KKMediaCell () 

@property (nonatomic, strong) UIImageView *placeholderImageView;
@property (nonatomic, strong) MMMaterialDesignSpinner *loadingIndicator;
@property (nonatomic, strong) DACircularProgressView *loadingProgress;
@property (nonatomic, strong) UIImageView *loadingError;

@end

@implementation KKMediaCell

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubview];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupSubview];
    }
    return self;
}

- (void)setupSubview {
    self.backgroundColor = [UIColor clearColor];
    
    [self addSubview:self.loadingProgress];
    [self addSubview:self.loadingIndicator];
    [self addSubview:self.loadingError];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat originY = 0;
    CGFloat originX = kMediaCellHorizontalPadding;
    CGFloat height = self.height;
    CGFloat width = self.width-2*kMediaCellHorizontalPadding;
    
    if (_placeholderImageView) {
        CGSize containerSize = CGSizeMake(width, height);
        CGRect imageViewFrame = [KKMediaBrowser convertImageSize:_placeholderImageView.image.size toContainerSize:containerSize isNeedToZoom:YES];
        imageViewFrame.origin.x += originX;
        imageViewFrame.origin.y += originY;
        
        _placeholderImageView.frame = imageViewFrame;
    }
    
    if (_loadingError) {
        _loadingError.width = 60;
        _loadingError.height = 60;
        _loadingError.centerX = self.width * 0.5;
        _loadingError.centerY = self.height * 0.5;
        [self bringSubviewToFront:_loadingError];
    }
    
    if (_loadingIndicator) {
        _loadingIndicator.width = 40;
        _loadingIndicator.height = 40;
        _loadingIndicator.centerX = self.width * 0.5;
        _loadingIndicator.centerY = self.height * 0.5;
        [self bringSubviewToFront:_loadingIndicator];
    }
    
    if (_loadingProgress) {
        _loadingProgress.width = 40;
        _loadingProgress.height = 40;
        _loadingProgress.centerX = self.width * 0.5;
        _loadingProgress.centerY = self.height * 0.5;
        [self bringSubviewToFront:_loadingProgress];
    }
    
}

#pragma mark - Override methds

- (void)displayData {
    
    id data = self.media.underlyingData;
    if (!data) return;
    [self hideLoadingIndicator];
    [self hidePlaceholderImage];
}

- (void)mediaBrowserCollectionViewDidScroll {
    
}

- (void)setMedia:(id<KKMediaProtocol>)media {
    if (_media && _media != media) {
        if ([_media respondsToSelector:@selector(cancelAnyLoading)]) {
            [_media cancelAnyLoading];
        }
    }
    _media = media;
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(media) weakMedia = media;
    media.progressUpdateBlock = ^(CGFloat progress) {
        [weakSelf setProgress:progress forMedia:weakMedia];
    };
    media.loadingEndBlock = ^(id<KKMediaProtocol> media) {
        [weakSelf handleMediaLoadingDidEnd:media];
    };
}

#pragma mark - Loading Progress

- (void)setProgress:(CGFloat)progress forMedia:(id<KKMediaProtocol>)media {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (media == self.media) {
            if (progress > 0.02) {
                [self hideLoadingIndicator];
                self.loadingProgress.hidden = NO;
                self.loadingProgress.progress = MAX(MIN(1, progress), 0);
            } else {
                _loadingProgress.hidden = YES;
                [self showLoadingIndicator];
            }
        }
    });
}

- (void)handleMediaLoadingDidEnd:(id<KKMediaProtocol>)media {
    if (self.media == media) {
        switch (media.dataStatus) {
            case KKMediaDataStatusFailure: {
                [self displayFailureImage];
            }
                break;
            case KKMediaDataStatusCancel: {
                [self setMedia:media];
            }
                break;
            case KKMediaDataStatusSuccess: {
                [self displayData];
                
                if ([self.delegate respondsToSelector:@selector(mediaCell:didLoadingEndMedia:)]) {
                    [self.delegate mediaCell:self didLoadingEndMedia:media];
                }
            }
                break;
            case KKMediaDataStatusLoading:
            default:
                break;
        }
    }
}

#pragma mark - UI operate

- (void)showPlaceholderImage:(id)image {
    
    BOOL hasPlaceholder = NO;
    if ([image isKindOfClass:UIImage.class]) {
        hasPlaceholder = YES;
        self.placeholderImageView.image = image;
    } else if ([image isKindOfClass:NSURL.class]) {
        hasPlaceholder = YES;
        [self.placeholderImageView yy_setImageWithURL:image
                                          placeholder:nil
                                              options:kNilOptions
                                           completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
                                               [self setNeedsLayout];
                                               [self layoutIfNeeded];
                                           }];
    }
    
    if (hasPlaceholder == NO) {
        self.placeholderImageView.hidden = YES;
        return;
    }
    
    self.placeholderImageView.hidden = NO;
    [self bringSubviewToFront:self.placeholderImageView];
}

- (void)hidePlaceholderImage {
    _placeholderImageView.hidden = YES;
}

- (void)hideLoadingIndicator {
    _loadingIndicator.hidden = YES;
    _loadingProgress.hidden = YES;
}

- (void)showLoadingIndicator {
    self.loadingIndicator.hidden = NO;
    [self.loadingIndicator startAnimating];
    [self bringSubviewToFront:self.loadingIndicator];
    [self hideFailureImage];
}

- (void)displayFailureImage {
    [self hideLoadingIndicator];
    self.loadingError.hidden = NO;
    [self bringSubviewToFront:self.loadingError];
}

- (void)hideFailureImage {
    _loadingError.hidden = YES;
}

#pragma mark - Getter

- (UIImageView *)placeholderImageView {
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc] init];
        _placeholderImageView.contentMode = UIViewContentModeScaleAspectFill;
        _placeholderImageView.hidden = YES;
        [self addSubview:_placeholderImageView];
    }
    return _placeholderImageView;
}

- (DACircularProgressView *)loadingProgress {
    if (!_loadingProgress) {
        _loadingProgress = [[DACircularProgressView alloc] init];
        _loadingProgress.thicknessRatio = 0.2;
        _loadingProgress.hidden = YES;
    }
    return _loadingProgress;
}

- (MMMaterialDesignSpinner *)loadingIndicator {
    if (!_loadingIndicator) {
        _loadingIndicator = [[MMMaterialDesignSpinner alloc] init];
        _loadingIndicator.lineWidth = 3.0;
        _loadingIndicator.tintColor = [UIColor whiteColor];
        _loadingIndicator.hidden = YES;
    }
    return _loadingIndicator;
}

- (UIImageView *)loadingError {
    if (!_loadingError) {
        _loadingError = [UIImageView new];
        _loadingError.image = [UIImage imageNamed:@"qrc_invalid"];
        _loadingError.hidden = YES;
    }
    return _loadingError;
}

@end
