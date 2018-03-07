//
//  KKVideoPlayer.m
//  Kook
//
//  Created by coze on 2017/9/15.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import "KKVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "KKVideoPlayerTransport.h"
#import "KKVideoPlayerView.h"

static NSString * const kStatusKeyPath = @"status";
static CGFloat const kRefreshInterval = 0.5f;
static NSString const * kPlayerItemStatusContext;

@interface KKVideoPlayer () <KKVideoPlayerTransportDelegate>

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) KKVideoPlayerView *playerView;

@property (nonatomic, weak) id<KKVideoPlayerTransport> transport;

@property (nonatomic, strong) id timeObserver;
@property (nonatomic, strong) id itemEndObserver;
@property (nonatomic, assign) float lastPlaybackRate;
@property (nonatomic, assign) BOOL readyToPlay;

@end

@implementation KKVideoPlayer


#pragma mark - Setup

- (instancetype)initWithURL:(NSURL *)assetURL {
    self = [super init];
    if (self) {
        _asset = [AVAsset assetWithURL:assetURL];
        _readyToPlay = NO;
        [self prepareToPlay];
    }
    return self;
}

- (void)prepareToPlay {
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    NSArray *keys = @[@"tracks", @"duration"];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset automaticallyLoadedAssetKeys:keys];
    
    [self.playerItem addObserver:self forKeyPath:kStatusKeyPath options:0 context:&kPlayerItemStatusContext];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    self.playerView = [[KKVideoPlayerView alloc] initWithPlayer:self.player];
    self.transport = self.playerView.transport;
    self.transport.delegate = self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == &kPlayerItemStatusContext) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.readyToPlay = YES;
            [self.playerItem removeObserver:self forKeyPath:kStatusKeyPath];
            
            if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
                
                [self addPlayerItemTimeObserver];
                [self addItemEndObserverForPlayerItem];
                
                CMTime duration = self.playerItem.duration;
                
                [self.transport setCurrentTime:CMTimeGetSeconds(kCMTimeZero) duration:CMTimeGetSeconds(duration)];
                
                [self.player play];
                
            } else {
                UIViewController *targetVC = self.view.window.rootViewController;
                if (targetVC) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Failed to load video" preferredStyle:UIAlertControllerStyleAlert];
                    [targetVC presentViewController:alert animated:YES completion:nil];
                }
            }
        });
    }
}

#pragma mark - Time Observers

- (void)addPlayerItemTimeObserver {
    
    CMTime interval = CMTimeMakeWithSeconds(kRefreshInterval, NSEC_PER_SEC);
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    __weak typeof(self) weakSelf = self;
    void (^callback)(CMTime time) = ^(CMTime time) {
        NSTimeInterval currentTime = CMTimeGetSeconds(time);
        NSTimeInterval duration = CMTimeGetSeconds(weakSelf.playerItem.duration);
        [weakSelf.transport setCurrentTime:currentTime duration:duration];
        if ([weakSelf.delegate respondsToSelector:@selector(playAtCurrentTime:duration:)]) {
            [weakSelf.delegate playAtCurrentTime:currentTime duration:duration];
        }
    };
    
    self.timeObserver =  [self.player addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:callback];
}

- (void)addItemEndObserverForPlayerItem {
    
    NSString *name = AVPlayerItemDidPlayToEndTimeNotification;
    
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    
    __weak typeof(self) weakSelf = self;
    void (^callback)(NSNotification *note) = ^(NSNotification *notification) {
        [weakSelf.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            [weakSelf.transport playbackComplete];
            if ([weakSelf.delegate respondsToSelector:@selector(playbackComplete)]) {
                [weakSelf.delegate playbackComplete];
            }
        }];
    };
    
    self.itemEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:name
                                                                             object:self.playerItem
                                                                              queue:queue
                                                                         usingBlock:callback];
}

- (void)dealloc {
    if (self.itemEndObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.itemEndObserver
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.player.currentItem];
        self.itemEndObserver = nil;
    }
    
    if (!self.readyToPlay) {
        [self.playerItem removeObserver:self forKeyPath:kStatusKeyPath];
    }
}

#pragma mark - KKVideoPlayerTransportDelegate Methods

- (void)play {
    [self.player play];
}

- (void)pause {
    self.lastPlaybackRate = self.player.rate;
    [self.player pause];
}

- (void)stop {
    [self.player setRate:0.0f];
    [self.transport playbackComplete];
    if ([self.delegate respondsToSelector:@selector(playbackComplete)]) {
        [self.delegate playbackComplete];
    }
}

- (void)jumpedToTime:(NSTimeInterval)time {
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
}

- (void)scrubbingDidStart {
    self.lastPlaybackRate = self.player.rate;
    [self.player pause];
    [self.player removeTimeObserver:self.timeObserver];
}

- (void)scrubbedToTime:(NSTimeInterval)time {
    [self.playerItem cancelPendingSeeks];
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
}

- (void)scrubbingDidEnd {
    [self addPlayerItemTimeObserver];
    if (self.lastPlaybackRate > 0.0f) {
        [self.player play];
    }
}

#pragma mark - Housekeeping

- (UIView *)view {
    return self.playerView;
}

@end
