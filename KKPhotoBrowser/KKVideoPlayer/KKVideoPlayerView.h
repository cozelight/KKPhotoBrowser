//
//  KKVideoPlayerView.h
//  Kook
//
//  Created by coze on 2017/9/14.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKVideoPlayerTransport.h"

@class AVPlayer;

@interface KKVideoPlayerView : UIView

- (instancetype)initWithPlayer:(AVPlayer *)player;

@property (nonatomic, readonly) id <KKVideoPlayerTransport> transport;

@end
