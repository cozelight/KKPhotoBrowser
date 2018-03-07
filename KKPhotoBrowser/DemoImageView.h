//
//  DemoImageView.h
//  KKPhotoBrowser
//
//  Created by coze on 2017/6/2.
//  Copyright © 2017年 kook.sdk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKMediaProtocol.h"

@interface DemoImageView : UIImageView

@property (nonatomic, strong) id<KKMediaProtocol> media;

@end
