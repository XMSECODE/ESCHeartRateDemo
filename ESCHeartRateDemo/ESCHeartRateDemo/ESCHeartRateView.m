//
//  ESCHeartRateView.m
//  ESCHeartRateDemo
//
//  Created by xiang on 2019/3/7.
//  Copyright © 2019 xiang. All rights reserved.
//

#import "ESCHeartRateView.h"

@interface ESCHeartRateView ()

@property(nonatomic,assign)double *arr;

@property(nonatomic,assign)int index;

@end

@implementation ESCHeartRateView

- (void)drawRect:(CGRect)rect {
    CGFloat height = rect.size.height;
    CGFloat width = rect.size.width;
    int step = 3;
    if (self.index >= width / step) {
        [[UIColor greenColor] setStroke];
        UIBezierPath *path = [UIBezierPath bezierPath];
        for (int i = self.index - width / step; i < self.index; i++) {
            CGFloat value = *(_arr + i);
            CGFloat y = height / 2 + value * height / 2;
            if (i == (int)(self.index - width / step)) {
                [path moveToPoint:CGPointMake(0, y)];
            }else {
                [path addLineToPoint:CGPointMake((i - (self.index - width / step)) * step, y)];
            }
        }
        path.lineWidth = 1;
        [path stroke];
    }else {
        [[UIColor greenColor] setStroke];
        UIBezierPath *path = [UIBezierPath bezierPath];
        for (int i = 0; i < self.index; i++) {
            CGFloat value = *(_arr + i);
            CGFloat y = height / 2 + value * height / 2;
            if (i == 0) {
                [path moveToPoint:CGPointMake(0, y)];
            }else {
                [path addLineToPoint:CGPointMake(i * step, y)];
            }
        }
        path.lineWidth = 1;
        [path stroke];
    }
    
}

- (void)addValue:(double)value {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.arr == nil) {
            self.arr = malloc(1024 * 1024 * 10);
        }
        *(_arr + self.index) = value;
        self.index++;
        [self setNeedsDisplay];
    });
}


@end
