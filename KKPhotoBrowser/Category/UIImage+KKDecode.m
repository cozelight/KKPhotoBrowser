//
//  UIImage+KKDecode.m
//  KKPhotoBrowser
//
//  Created by coze on 2017/6/22.
//  Copyright © 2017年 kook.sdk. All rights reserved.
//

#import "UIImage+KKDecode.h"

@implementation UIImage (KKDecode)

- (UIImage *)scaleToSize:(CGSize)size {
    return [self scaleToSize:size cornerRadius:0];
}

- (UIImage *)scaleToSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius {
    UIImage *newImage = nil;
    CGSize imageSize = self.size;
    CGFloat width = CGImageGetWidth(self.CGImage);
    CGFloat height = CGImageGetHeight(self.CGImage);
    CGFloat targetWidth = size.width;
    CGFloat targetHeight = size.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointZero;
    if (!CGSizeEqualToSize(imageSize, size)) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor;
        } else {
            scaleFactor = heightFactor;
        }
        
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = ceilf(scaledWidth);
    thumbnailRect.size.height = scaledHeight;
    if (cornerRadius >= 0.1) {
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:cornerRadius] addClip];
    }
    [self drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
