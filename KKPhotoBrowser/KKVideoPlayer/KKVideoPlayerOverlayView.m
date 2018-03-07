//
//  KKVideoPlayerOverlayView.m
//  Kook
//
//  Created by coze on 2017/9/14.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import "KKVideoPlayerOverlayView.h"
#import "NSTimer+KKAdditions.h"

@interface KKVideoPlayerOverlayView ()

@property (nonatomic, assign) BOOL controlsHidden;
@property (nonatomic, assign) BOOL scrubbing;
@property (nonatomic, assign) CGFloat lastPlaybackRate;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation KKVideoPlayerOverlayView

#pragma mark - Init

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.scrubberSlider setThumbImage:[UIImage imageNamed:@"video_slider_btn"] forState:UIControlStateNormal];
    self.smallPlayButton.selected = YES;
    
    [self toggleControlsHidden:YES animated:NO];
}

#pragma mark - KKVideoPlayerTransport

- (void)setCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration {
    NSInteger currentSeconds = ceilf(time);
    NSInteger durationSeconds = ceil(duration);
    self.currentTimeLabel.text = [self formatSeconds:currentSeconds];
    self.totalTimeLabel.text = [self formatSeconds:durationSeconds];
    self.scrubberSlider.minimumValue = 0.0f;
    self.scrubberSlider.maximumValue = duration;
    self.scrubberSlider.value = time;
}

- (void)playbackComplete {
    self.scrubberSlider.value = 0.0f;
    self.currentTimeLabel.text = [self formatSeconds:0.0f];
    self.smallPlayButton.selected = NO;
}

#pragma mark - Private methods

- (void)resetTimer {
    [self.timer invalidate];
    if (!self.scrubbing) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 firing:^{
            if (self.timer.isValid && !self.controlsHidden) {
                [self toggleControlsHidden:YES animated:YES];
            }
        }];
    }
}

- (NSString *)formatSeconds:(NSInteger)value {
    NSInteger seconds = value % 60;
    NSInteger minutes = value / 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long) minutes, (long) seconds];
}


#pragma mark - Public methods

- (void)stopPlayer {
    if ([self.delegate respondsToSelector:@selector(stop)]) {
        [self.delegate stop];
    }
    [self playbackComplete];
}

- (void)startPlayer {
    if (!self.smallPlayButton.selected) {
        [self smallPlayButtonDidClick:self.smallPlayButton];
    }
}

- (void)pausePlayer {
    if (self.smallPlayButton.selected) {
        [self smallPlayButtonDidClick:self.smallPlayButton];
    }
}

- (void)toggleControlsHidden:(BOOL)hidden animated:(BOOL)animated {
    CGFloat duration = 0.0;
    if (animated) {
        duration = 0.35;
    }
    [UIView animateWithDuration:duration animations:^{
        self.bottomShadowView.hidden = hidden;
        self.controlsHidden = hidden;
    }];
}

#pragma mark - Actions

- (IBAction)smallPlayButtonDidClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        if ([self.delegate respondsToSelector:@selector(play)]) {
            [self.delegate play];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(pause)]) {
            [self.delegate pause];
        }
    }
}

- (IBAction)scrubberSliderDidStart:(id)sender {
    self.scrubbing = YES;
    [self resetTimer];
    if ([self.delegate respondsToSelector:@selector(scrubbingDidStart)]) {
        [self.delegate scrubbingDidStart];
    }
}

- (IBAction)scrubberSliderDidChange:(id)sender {
    
    self.currentTimeLabel.text = [self formatSeconds:self.scrubberSlider.value];
    
    if ([self.delegate respondsToSelector:@selector(scrubbedToTime:)]) {
        [self.delegate scrubbedToTime:self.scrubberSlider.value];
    }
}

- (IBAction)scrubberSliderDidEnd:(id)sender {
    self.scrubbing = NO;
    if ([self.delegate respondsToSelector:@selector(scrubbingDidEnd)]) {
        [self.delegate scrubbingDidEnd];
    }
}


@end
