//
//  KKMediaCell.h
//  KKPhotoBrowser
//
//  Created by coze on 2017/6/2.
//  Copyright © 2017年 kook.sdk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKMediaProtocol.h"

UIKIT_EXTERN CGFloat kMediaCellHorizontalPadding;

@class KKMediaCell;

@protocol KKMediaCellDelegate <NSObject>

@optional

- (void)mediaCellDidClose:(KKMediaCell *)cell;
- (void)mediaCellDidMenu:(KKMediaCell *)cell;
- (void)mediaCell:(KKMediaCell *)mediaCell didLoadingEndMedia:(id<KKMediaProtocol>)media;

@end

@interface KKMediaCell : UICollectionViewCell

@property (nonatomic, strong) id<KKMediaProtocol> media;

@property (nonatomic, weak) id<KKMediaCellDelegate> delegate;

@property (nonatomic, assign) BOOL zoomMediaToFill;

- (void)displayData;

- (void)mediaBrowserCollectionViewDidScroll;

- (void)showPlaceholderImage:(id)image;

- (void)hidePlaceholderImage;

- (void)hideLoadingIndicator;

- (void)showLoadingIndicator;

- (void)displayFailureImage;

- (void)hideFailureImage;

@end
