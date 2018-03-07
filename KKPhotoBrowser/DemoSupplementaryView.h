//
//  DemoSupplementaryView.h
//  KKPhotoBrowser
//
//  Created by coze on 2017/6/15.
//  Copyright © 2017年 kook.sdk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KKMediaProtocol.h"

@interface DemoSupplementaryView : UIView <KKMediaSupplementaryViewProtocol>

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, assign) BOOL isHeader;

@end
