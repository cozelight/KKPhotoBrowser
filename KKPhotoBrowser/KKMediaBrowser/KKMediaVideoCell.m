//
//  KKMediaVideoCell.m
//  Kook
//
//  Created by coze on 2017/8/8.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import "KKMediaVideoCell.h"
#import "KKVideoPlayer.h"
#import "KKVideoPlayerView.h"
#import "KKVideoPlayerOverlayView.h"
#import "NSTimer+KKAdditions.h"
#import "KKView+Base.h"

@interface KKMediaVideoCell () <KKVideoPlayerDelegate>

@property (nonatomic, strong) UIView *topShadowView;

@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) UIButton *menuButton;

@property (nonatomic, strong) UIImageView *topShadowImageView;

@property (nonatomic, strong) UIButton *playButton;

@property (nonatomic, strong) KKVideoPlayer *videoPlayer;

@property (nonatomic, weak, readonly) KKVideoPlayerOverlayView *overlayView;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) BOOL isCanPlay;

@end

@implementation KKMediaVideoCell

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
    
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playButton setImage:[UIImage imageNamed:@"video_play_big_icon"] forState:UIControlStateNormal];
    [_playButton setImage:[UIImage imageNamed:@"video_play_big_pressed"] forState:UIControlStateHighlighted];
    [_playButton addTarget:self action:@selector(playButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_playButton];
    
    _topShadowView = [[UIView alloc] init];
    _topShadowView.backgroundColor = [UIColor clearColor];
    [self addSubview:_topShadowView];
    
    _topShadowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"video_top_shadow"]];
    _topShadowImageView.contentMode = UIViewContentModeScaleAspectFill;
    [_topShadowView addSubview:_topShadowImageView];
    
    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeButton setImage:[UIImage imageNamed:@"common_close_btn"] forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(closeButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [_topShadowView addSubview:_closeButton];
    
    _menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_menuButton setImage:[UIImage imageNamed:@"video_menu_btn"] forState:UIControlStateNormal];
    [_menuButton addTarget:self action:@selector(menuButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [_topShadowView addSubview:_menuButton];
    
    _topShadowView.hidden = YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat originY = 0;
    CGFloat originX = kMediaCellHorizontalPadding;
    CGFloat height = self.height;
    CGFloat width = self.width-2*kMediaCellHorizontalPadding;
    
    if (_displayView) {
        _displayView.frame = CGRectMake(originX, originY, width, height);
    }
    
    if (@available(iOS 11.0, *)) {
        originY = self.safeAreaLayoutGuide.layoutFrame.origin.y;
        originX = self.safeAreaLayoutGuide.layoutFrame.origin.x + kMediaCellHorizontalPadding;
        height = self.safeAreaLayoutGuide.layoutFrame.size.height;
        width = self.safeAreaLayoutGuide.layoutFrame.size.width - 2*kMediaCellHorizontalPadding;
    }
    
    _topShadowView.frame = CGRectMake(originX, originY, width, 40);
    _topShadowImageView.frame = _topShadowView.bounds;
    _closeButton.frame = CGRectMake(10, 10, 40, 40);
    
    _menuButton.frame = CGRectMake(0, 10, 40, 40);
    _menuButton.right = _topShadowView.width  - 15;
    
    _playButton.width = 80;
    _playButton.height = 80;
    _playButton.centerX = self.width * 0.5;
    _playButton.centerY = self.height * 0.5;
    
    [self bringSubviewToFront:_playButton];
    [self bringSubviewToFront:_topShadowView];
}

#pragma mark - Override methods

- (void)setMedia:(id<KKMediaProtocol>)media {
    [super setMedia:media];
    
    id placeholderImg = nil;
    if ([media respondsToSelector:@selector(placeholderImage)]) {
        placeholderImg = media.placeholderImage;
    }
    if (placeholderImg) {
        [self showPlaceholderImage:placeholderImg];
    } else {
        [self hidePlaceholderImage];
    }
    
    if (self.showControlView) {
        [self showPlayButton:YES];
    } else {
        [self loadDisplayData];
    }
}

- (void)displayData {
    
    if (self.isCanPlay == NO) {
        [self showPlayButton:YES];
        return;
    }
    
    NSURL *videoPath = self.media.underlyingData;
    NSURL *url;
    if ([videoPath isKindOfClass:NSURL.class]) {
        url = videoPath;
    } else if ([videoPath isKindOfClass:NSString.class]) {
        url = [NSURL fileURLWithPath:(NSString *)videoPath];
    }
    
    if (!url) {
        return;
    }
    
    self.videoPlayer = [[KKVideoPlayer alloc] initWithURL:url];
    self.videoPlayer.delegate = self;
    _displayView = (KKVideoPlayerView *)self.videoPlayer.view;
    [self addSubview:self.displayView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlay) name:UIApplicationWillResignActiveNotification object:nil];
    
    [self hideLoadingIndicator];
    [self hideFailureImage];
}

- (void)mediaBrowserCollectionViewDidScroll {
    if ([self.media respondsToSelector:@selector(cancelAnyLoading)]) {
        [self.media cancelAnyLoading];
    }
    [self hideFailureImage];
    [self stopPlay];
}

- (void)showLoadingIndicator {
    [super showLoadingIndicator];
    self.playButton.hidden = YES;
}

- (void)displayFailureImage {
    [super displayFailureImage];
    self.playButton.hidden = YES;
}

#pragma mark - Action

- (void)playButtonDidClick:(UIButton *)button {
    
    [self showPlayButton:NO];
    
    [self loadDisplayData];
    
    if (!_topShadowView.hidden) {
        [self toggleControls];
    }
}

- (void)closeButtonDidClick:(UIButton *)button {
    [self stopPlay];
    if ([self.delegate respondsToSelector:@selector(mediaCellDidClose:)]) {
        [self.delegate mediaCellDidClose:self];
    }
}

- (void)menuButtonDidClick:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(mediaCellDidMenu:)]) {
        [self.delegate mediaCellDidMenu:self];
    }
}

- (void)pausePlay {
    [self.overlayView pausePlayer];
}

#pragma mark - Public methods

- (void)startPlay {
    [self playButtonDidClick:self.playButton];
}

- (void)stopPlay {
    [self.overlayView stopPlayer];
    [self showPlayButton:YES];
}

- (void)toggleControls {
    [UIView animateWithDuration:0.25 animations:^{
        _topShadowView.hidden = !_topShadowView.isHidden;
        [self.overlayView toggleControlsHidden:_topShadowView.hidden animated:NO];
    }];
    
    [self resetTimer];
}

#pragma mark - Private methods

- (void)showPlayButton:(BOOL)show {
    self.isCanPlay = NO;
    if (show) {
        
        if (self.media.placeholderImage) {
            [self showPlaceholderImage:self.media.placeholderImage];
        }
        
        self.playButton.hidden = NO;
        self.videoPlayer = nil;
        [self.displayView removeFromSuperview];
        _displayView = nil;
        
        [self hideLoadingIndicator];
        [self hideFailureImage];
    } else {
        self.playButton.hidden = YES;
    }
}

- (void)loadDisplayData {
    self.isCanPlay = YES;
    if (self.media.underlyingData) {
        [self displayData];
    } else {
        [self.media loadUnderlyingDataAndNotify];
        [self showLoadingIndicator];
    }
}

- (void)resetTimer {
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 firing:^{
        if (self.timer.isValid && !_topShadowView.hidden) {
            [self toggleControls];
        }
    }];
}

#pragma mark - KKVideoPlayerDelegate

- (void)playbackComplete {
    [self showPlayButton:YES];
    
    if (!_topShadowView.hidden) {
        [self toggleControls];
    }
}

- (void)playAtCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration {
    if (time > 0) {
        [self hidePlaceholderImage];
    }
}

#pragma mark - Getter

- (KKVideoPlayerOverlayView *)overlayView {
    return (KKVideoPlayerOverlayView *)self.displayView.transport;
}

@end
