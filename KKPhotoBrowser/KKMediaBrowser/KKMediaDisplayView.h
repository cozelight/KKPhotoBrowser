//
//  KKMediaDisplayView.h
//  Kook
//
//  Created by coze on 2017/8/8.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKMediaProtocol.h"

@class YYAnimatedImageView;

@interface KKMediaDisplayView : UIView

@property (nonatomic, strong) YYAnimatedImageView *imageView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *imageContainerView;

@property (nonatomic, strong) id<KKMediaProtocol> media;
@property (nonatomic, assign) BOOL zoomMediaToFill;

- (void)displayData;
- (void)handleDoubleTap:(CGPoint)touchPoint;

@end
