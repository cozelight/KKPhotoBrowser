//
//  NSTimer+KKAdditions.m
//  Kook
//
//  Created by coze on 2017/9/14.
//  Copyright © 2017年 Kook. All rights reserved.
//

#import "NSTimer+KKAdditions.h"

@implementation NSTimer (KKAdditions)

+ (void)executeTimerBlock:(NSTimer *)timer {
    KKTimerFireBlock block = [timer userInfo];
    block();
}

+ (id)scheduledTimerWithTimeInterval:(NSTimeInterval)interval firing:(KKTimerFireBlock)fireBlock {
    return [self scheduledTimerWithTimeInterval:interval repeating:NO firing:fireBlock];
}

+ (id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval repeating:(BOOL)repeat firing:(KKTimerFireBlock)fireBlock {
    id block = [fireBlock copy];
    return [self scheduledTimerWithTimeInterval:inTimeInterval target:self selector:@selector(executeTimerBlock:) userInfo:block repeats:repeat];
}

@end
