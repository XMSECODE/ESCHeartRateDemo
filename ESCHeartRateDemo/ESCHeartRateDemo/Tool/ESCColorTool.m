//
//  ESCColorTool.m
//  ESCHeartRateDemo
//
//  Created by xiang on 2019/3/7.
//  Copyright © 2019 xiang. All rights reserved.
//

#import "ESCColorTool.h"

@implementation ESCColorTool

+ (double)calculateHValueWithBuffer:(uint8_t *)buffer width:(int)width height:(int)height {
    
    NSInteger totalR = 0;
    NSInteger totalG = 0;
    NSInteger totalB = 0;
    
    for (int i = 0; i < height * width; i++) {
        int b = buffer[i * 4];
        int g = buffer[i * 4 + 1];
        int r = buffer[i * 4 + 2];
        totalR += r;
        totalG += g;
        totalB += b;
    }
    
    double averageR = totalR * 1.0 / (width * height);
    double averageG = totalG * 1.0 / (width * height);
    double averageB = totalB * 1.0 / (width * height);
    double H = [ESCColorTool getHFromR:averageR g:averageG b:averageB];
    return H;
}

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
