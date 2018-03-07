//
//  DemoSupplementaryView.m
//  KKPhotoBrowser
//
//  Created by coze on 2017/6/15.
//  Copyright © 2017年 kook.sdk. All rights reserved.
//

#import "DemoSupplementaryView.h"

@implementation DemoSupplementaryView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupSupplementary];
    }
    return self;
}

- (void)setupSupplementary {
    _label = [[UILabel alloc] init];
    _label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _label.opaque = NO;
    _label.backgroundColor = [UIColor clearColor];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.lineBreakMode = NSLineBreakByWordWrapping;
    _label.numberOfLines = 3;
    _label.textColor = [UIColor whiteColor];
    _label.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
    _label.shadowOffset = CGSizeMake(0, 1);
    _label.font = [UIFont systemFontOfSize:17];
    
    [self addSubview:_label];
}

- (CGSize)sizeThatFits:(CGSize)size {
    if (_label.text.length == 0) return CGSizeZero;
    
    CGFloat maxHeight = 9999;
    if (_label.numberOfLines > 0) maxHeight = _label.font.leading*_label.numberOfLines;
    
    
    CGFloat width = size.width - 10*2;
    
    CGFloat height = [_label sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
    return CGSizeMake(size.width, height + 10 * 2);
}

- (CGRect)layoutSupplementaryViewThatFrame:(CGRect)frame {
    CGRect newFrame = CGRectZero;
    CGSize size = CGSizeMake(134, 25);
    CGFloat height = 60;
    if (!_isHeader) {
        height = frame.size.height-size.height-20;
    }
    newFrame = CGRectMake((frame.size.width - size.width)*0.5, height, size.width, size.height);
    self.frame = newFrame;
    return newFrame;
}

@end
