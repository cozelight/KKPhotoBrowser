//
//  KKVideoPlayer.h
//  Kook
//
//  Created by coze on 2017/9/15.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KKVideoPlayerDelegate <NSObject>

@optional

- (void)playbackComplete;
- (void)playAtCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration;

@end

@interface KKVideoPlayer : NSObject

- (instancetype)initWithURL:(NSURL *)assetURL;

@property (nonatomic, strong, readonly) UIView *view;

@property (nonatomic, weak) id<KKVideoPlayerDelegate> delegate;

@end
