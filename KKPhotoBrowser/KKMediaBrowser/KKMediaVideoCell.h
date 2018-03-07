//
//  KKMediaVideoCell.h
//  Kook
//
//  Created by coze on 2017/8/8.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import "KKMediaCell.h"

@class KKVideoPlayerView;

@interface KKMediaVideoCell : KKMediaCell

@property (nonatomic, strong, readonly) KKVideoPlayerView *displayView;
@property (nonatomic, assign) BOOL showControlView;

- (void)startPlay;

- (void)stopPlay;

- (void)toggleControls;

@end
