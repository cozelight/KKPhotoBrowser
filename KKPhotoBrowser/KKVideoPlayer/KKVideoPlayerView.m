//
//  KKVideoPlayerView.m
//  Kook
//
//  Created by coze on 2017/9/14.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import "KKVideoPlayerView.h"
#import "KKVideoPlayerOverlayView.h"

@interface KKVideoPlayerView ()

@property (nonatomic, strong) KKVideoPlayerOverlayView *overlayView;

@end

@implementation KKVideoPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (instancetype)initWithPlayer:(AVPlayer *)player {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [(AVPlayerLayer *)[self layer] setPlayer:player];
        
        _overlayView = [[NSBundle mainBundle] loadNibNamed:@"KKVideoPlayerOverlayView" owner:self options:nil].firstObject;
        
        [self addSubview:_overlayView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.overlayView.frame = self.bounds;
}

- (id<KKVideoPlayerTransport>)transport {
    return self.overlayView;
}

@end
