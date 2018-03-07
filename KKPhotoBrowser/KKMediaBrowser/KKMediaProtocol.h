//
//  KKMediaProtocol.h
//  KKMediaBrowser
//
//  Created by coze on 2017/5/26.
//  Copyright © 2017年 kook.sdk. All rights reserved.
//

#ifndef KKMediaProtocol_h
#define KKMediaProtocol_h

#import <UIKit/UIKit.h>

@protocol KKMediaProtocol;

typedef void (^KKMediaProgressUpdateBlock)(CGFloat progress);
typedef void (^KKMediaLoadingEndBlock)(id<KKMediaProtocol> media);

typedef NS_ENUM(NSUInteger, KKMediaType) {
    KKMediaTypePhoto,
    KKMediaTypeGif,
    KKMediaTypeVideo,
};

typedef NS_ENUM(NSUInteger, KKMediaDataStatus) {
    KKMediaDataStatusSuccess,
    KKMediaDataStatusLoading,
    KKMediaDataStatusFailure,
    KKMediaDataStatusCancel,
};

@protocol KKMediaProtocol <NSObject>

@required

/// 根据mediaType，返回不同数据：UIImage/NSData/NSString
@property (nonatomic, strong) id underlyingData;

@property (nonatomic, assign) KKMediaType mediaType;

@property (nonatomic, assign) KKMediaDataStatus dataStatus;

@property (nonatomic, copy) KKMediaProgressUpdateBlock progressUpdateBlock;

@property (nonatomic, copy) KKMediaLoadingEndBlock loadingEndBlock;

- (void)loadUnderlyingDataAndNotify;

- (void)performLoadUnderlyingDataAndNotify;

- (void)unloadUnderlyingData;

@optional

@property (nonatomic, strong) id placeholderImage;

- (void)cancelAnyLoading;

@end


@protocol KKMediaSupplementaryViewProtocol <NSObject>

- (CGRect)layoutSupplementaryViewThatFrame:(CGRect)frame;

@end

#endif /* KKMediaProtocol_h */
