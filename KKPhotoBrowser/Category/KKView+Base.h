//
//  KKView+Base.h
//  zft
//
//  Created by YiLee on 12-11-21.
//  Copyright (c) 2012年 LiveByTouch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Base)
- (CGFloat)left;
- (void)setLeft:(CGFloat)x;
- (CGFloat)top;
- (void)setTop:(CGFloat)y;
- (CGFloat)right;
- (void)setRight:(CGFloat)right;
- (CGFloat)bottom;
- (void)setBottom:(CGFloat)bottom;
- (CGFloat)width;
- (void)setWidth:(CGFloat)width;
- (CGFloat)height;
- (void)setHeight:(CGFloat)height;
- (CGFloat)centerX;
- (void)setCenterX:(CGFloat)centerX;
- (CGFloat)centerY;
- (void)setCenterY:(CGFloat)centerY;
- (CGPoint)origin;
- (void)setOrigin:(CGPoint)origin;
- (CGSize)size;
- (void)setSize:(CGSize)size;

#if TARGET_OS_IPHONE
//适配
-(CGFloat)tabHeight;  //减掉Tab栏 Nav栏 Status栏
-(CGFloat)allHeight;  //所有高度
-(CGFloat)normalHeight; //减掉Nav栏 Status栏
#endif
@end
