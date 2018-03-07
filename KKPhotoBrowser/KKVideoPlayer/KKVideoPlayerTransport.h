//
//  KKVideoPlayerTransport.h
//  Kook
//
//  Created by coze on 2017/9/14.
//  Copyright © 2017年 Kook. All rights reserved.
//

#ifndef KKVideoPlayerTransport_h
#define KKVideoPlayerTransport_h

#import <AVFoundation/AVFoundation.h>

@protocol KKVideoPlayerTransportDelegate <NSObject>

- (void)play;
- (void)pause;
- (void)stop;

@optional

- (void)scrubbingDidStart;
- (void)scrubbedToTime:(NSTimeInterval)time;
- (void)scrubbingDidEnd;

- (void)jumpedToTime:(NSTimeInterval)time;

@end

@protocol KKVideoPlayerTransport <NSObject>

@property (weak, nonatomic) id <KKVideoPlayerTransportDelegate> delegate;

- (void)setCurrentTime:(NSTimeInterval)time duration:(NSTimeInterval)duration;
- (void)playbackComplete;

@end


#endif /* KKVideoPlayerTransport_h */
