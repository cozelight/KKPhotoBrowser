//
//  KKMedia.h
//  KKPhotoBrowser
//
//  Created by coze on 2017/5/26.
//  Copyright © 2017年 kook.sdk. All rights reserved.
//

#import "KKMediaProtocol.h"
#import <Photos/Photos.h>

@interface KKMedia : NSObject <KKMediaProtocol>

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *placeholderImage;

+ (KKMedia *)mediaWithImage:(UIImage *)image;
+ (KKMedia *)mediaWithPhotoURL:(NSURL *)url;
+ (KKMedia *)mediaWithVideoURL:(NSURL *)url;

@end
