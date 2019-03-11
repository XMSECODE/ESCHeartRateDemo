//
//  ESCHeartRateView.m
//  ESCHeartRateDemo
//
//  Created by xiang on 2019/3/7.
//  Copyright © 2019 xiang. All rights reserved.
//

#import "ESCHeartRateView.h"


struct ESCValueStruct {
    double value;
    struct ESCValueStruct *preStruct;
    struct ESCValueStruct *nextStruct;
};

typedef struct ESCValueStruct ESCValueStruct;

@interface ESCHeartRateView ()

@property(nonatomic,assign)ESCValueStruct *currentValueStruct;

@property(nonatomic,assign)void *data;

@end

@implementation ESCHeartRateView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        int dataCount = 1024 * 4;
        void *data = malloc(sizeof(ESCValueStruct) * dataCount);
        self.data = data;
        ESCValueStruct *firstPoint = data;
        firstPoint->value = 0;
        ESCValueStruct *lastPoint = firstPoint;
        
        for (int i = 1; i < dataCount; i++) {
            ESCValueStruct *currentValueStruct = (data + sizeof(ESCValueStruct) * i);
            currentValueStruct->value = 0;
            lastPoint->nextStruct = currentValueStruct;
            currentValueStruct->preStruct = lastPoint;
            lastPoint = currentValueStruct;
        }
        
        lastPoint->nextStruct = firstPoint;
        firstPoint->preStruct = lastPoint;
        
        self.currentValueStruct = data;
           
    }
    return self;
}

- (void)dealloc {
    free(self.data);
}

- (void)drawRect:(CGRect)rect {
    CGFloat height = rect.size.height;
    CGFloat width = rect.size.width;
    int step = 2;
    [[UIColor greenColor] setStroke];
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = 1;

    CGFloat value = self.currentValueStruct->value;
    CGFloat y = height / 2 - value * height / 2;
    [path moveToPoint:CGPointMake(width, y)];

    ESCValueStruct *valueStruct = self.currentValueStruct->preStruct;
    
    for (int i = 1; i < width / step; i++) {
        CGFloat value = valueStruct->value;
        CGFloat y = height / 2 - value * height / 2;
        [path addLineToPoint:CGPointMake(width - i * step, y)];
        valueStruct = valueStruct->preStruct;
    }
    [path stroke];
}

- (void)addValue:(double)value {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentValueStruct->nextStruct->value = value;
        self.currentValueStruct = self.currentValueStruct->nextStruct;
        [self setNeedsDisplay];
    });
}


@end
