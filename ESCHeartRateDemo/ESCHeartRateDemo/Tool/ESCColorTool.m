//
//  ESCColorTool.m
//  ESCHeartRateDemo
//
//  Created by xiang on 2019/3/7.
//  Copyright © 2019 xiang. All rights reserved.
//

#import "ESCColorTool.h"

@implementation ESCColorTool

+ (double)getHFromR:(double)r g:(double)g b:(double)b {
    
    double max = MAX(r, MAX(g, b));
    double min = MIN(r, MIN(g, b));
    double off = max - min;
    
    if (max == min) {
        return 0;
    }
    if (max == r && g >= b) {
        return 60.0 * (g - b) / off;
    }
    if (max == r && g < b) {
        return 60.0 * (g - b) / off + 360;
    }
    if (max == g) {
        return 60.0 * (b - r) / off + 120;
    }else {
        return 60.0 * (r - g) / off + 240;
    }
}

+ (double)getSFromR:(double)r g:(double)g b:(double)b {
    double max = MAX(r, MAX(g, b));
    double min = MIN(r, MIN(g, b));
    
    if (max == 0) {
        return 0;
    }else {
        return 1.0 - (min  * 1.0/ max);
    }
}

+ (double)getVFromR:(double)r g:(double)g b:(double)b {
    double max = MAX(r, MAX(g, b));
    
    return max / 255.0;
}


@end
