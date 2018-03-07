//
//  NSTimer+KKAdditions.h
//  Kook
//
//  Created by coze on 2017/9/14.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^KKTimerFireBlock)(void);

@interface NSTimer (KKAdditions)

+ (id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval firing:(KKTimerFireBlock)fireBlock;

+ (id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval repeating:(BOOL)repeat firing:(KKTimerFireBlock)fireBlock;

@end
