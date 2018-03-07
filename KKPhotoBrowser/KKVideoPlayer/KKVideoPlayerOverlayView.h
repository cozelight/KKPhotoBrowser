//
//  KKVideoPlayerOverlayView.h
//  Kook
//
//  Created by coze on 2017/9/14.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKVideoPlayerTransport.h"

@interface KKVideoPlayerOverlayView : UIView <KKVideoPlayerTransport>

@property (nonatomic, weak) IBOutlet UIView *bottomShadowView;
@property (nonatomic, weak) IBOutlet UIButton *smallPlayButton;
@property (nonatomic, weak) IBOutlet UILabel *currentTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *totalTimeLabel;
@property (nonatomic, weak) IBOutlet UISlider *scrubberSlider;

@property (nonatomic, weak) id<KKVideoPlayerTransportDelegate> delegate;

- (void)stopPlayer;
- (void)pausePlayer;
- (void)toggleControlsHidden:(BOOL)hidden animated:(BOOL)animated;

@end
