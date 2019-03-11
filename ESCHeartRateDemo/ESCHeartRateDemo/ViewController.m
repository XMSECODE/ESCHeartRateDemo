//
//  ViewController.m
//  ESCHeartRateDemo
//
//  Created by xiang on 2019/3/6.
//  Copyright © 2019 xiang. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "ESCHeartRateView.h"
#import "Tool/ESCImageTool.h"
#import "Tool/ESCColorTool.h"
#import "ESCCameraTool.h"

/*
 参考博客：
 https://blog.csdn.net/fishmai/article/details/73457457
 https://blog.csdn.net/qq_30513483/article/details/52604148
 */


@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *perMLabel;

@property(nonatomic,strong)ESCCameraTool* cameratool;

@property(nonatomic,assign)BOOL isRecording;

@property(nonatomic,weak)ESCHeartRateView* heartRateView;

@property(nonatomic,strong)NSMutableArray* points;

@property(nonatomic,assign)BOOL isWait;

@property(nonatomic,assign)int T;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.T = 30;
    
    self.startButton.backgroundColor = [UIColor greenColor];
    self.startButton.layer.cornerRadius = 50;
    self.startButton.layer.masksToBounds = YES;
    [self.startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    self.points = [NSMutableArray array];
    ESCHeartRateView *heartRateView = [[ESCHeartRateView alloc] init];
    self.heartRateView = heartRateView;
    heartRateView.frame = CGRectMake(0, 200, self.view.frame.size.width,200);
    [self.view addSubview:heartRateView];
    self.heartRateView.backgroundColor = [UIColor blackColor];
    
    self.cameratool = [[ESCCameraTool alloc] init];
    self.cameratool.delegate = self;
    
}

- (IBAction)didClickStartButton:(id)sender {
    if (self.isRecording) {
        [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
        [self.cameratool stop];
        NSLog(@"结束");
    }else {
        [self.startButton setTitle:@"结束" forState:UIControlStateNormal];
        [self.cameratool start];
        NSLog(@"开始");
    }
    self.isRecording = !self.isRecording;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    /** 读取图像Buffer */
    CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    uint8_t*buf = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    double H = [ESCColorTool calculateHValueWithBuffer:buf width:(int)width height:(int)height];

    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    float result = [self differenceThresholdArithmetic:H];
    
    if (self.isWait == YES) {
        return;
    }
    if (result >= 1.0 || result <= -1.0 ) {
        count = 0;
        lastValue = 0;
        [self.points removeAllObjects];
        self.isWait = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.isWait = NO;
        });
        return;
    }
    [self.heartRateView addValue:result];
    double t = [[NSDate date] timeIntervalSince1970]*1000;
    NSDictionary *point = @{[NSNumber numberWithDouble:t]:[NSNumber numberWithFloat:result]};
    [self analysisPointsWith:point];
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 6_0) {
    NSLog(@"did drop %@",output);
}
// 记录浮点变化的前一次的值
static float lastValue = 0;
// 用于判断是否是第一个福点值
static int   count = 0;
//使用差分阈值法处理数据
- (float)differenceThresholdArithmetic:(float)value {
    float low = 0;
    count++;
    lastValue = (count == 1) ? value : lastValue;
    low = (value - lastValue);
    lastValue = value;
    return low;
}

//使用基音检测算法求周期
- (void)analysisPointsWith:(NSDictionary *)point {
    
    [self.points addObject:point];
    //样本过少
    if (self.points.count <= self.T * 3){
        return;
    }
    int count = (int)self.points.count;
    
    int minIndex = 0;                   //最低峰值的位置 姑且算在中间位置
    int minLeftMinIndex = 0;          //最低峰值左面的最低峰值位置
    int minRightMinIndex = 0;          //最低峰值右面的最低峰值位置
    
    float minTroughValue = 0;     //最低峰值的浮点值
    float minLeftTroughValue = 0;     //最低峰值左面的最低峰值浮点值
    float minRightTroughValue = 0;     //最低峰值右面的最低峰值浮点值
    
    // 1.先确定数据中的最低峰值
    for (int i = 0; i < count; i++) {
        float trough = [[[self.points[i] allObjects] firstObject] floatValue];
        if (trough < minTroughValue) {
            minTroughValue = trough;
            minIndex = i;
        }
    }
    
    //2.求左边峰值，如果左边的周期大于0.5个周期，则求出左边的峰值
    if (minIndex > 0.5 * self.T) {
        int startLeftIndex = minIndex - 1.5 * self.T;
        if (startLeftIndex < 0) {
            startLeftIndex = 0;
        }
        for (int j = startLeftIndex; j < minIndex - 0.5 * self.T; j++) {
            float trough = [[[self.points[j] allObjects] firstObject] floatValue];
            if ((trough < minLeftTroughValue) && (minIndex - j) <= self.T) {
                minLeftTroughValue = trough;
                minLeftMinIndex = j;
            }
        }
    }
    
    //3.求右边峰值,如果右边的周期大于0.5个周期，则求出右边的峰值
    if (minIndex < count - 0.5 * self.T) {
        int endRightIndex = minIndex + 1.5 * self.T;
        if (endRightIndex > count) {
            endRightIndex = count;
        }
        for (int k = minIndex + 0.5 * self.T; k < endRightIndex; k++) {
            float trough = [[[self.points[k] allObjects] firstObject] floatValue];
            if ((trough < minRightTroughValue) && (k - minIndex <= self.T)) {
                minRightTroughValue = trough;
                minRightMinIndex = k;
            }
        }
    }
    
    // 3. 确定哪一个与最低峰值更接近 用最接近的一个最低峰值测出瞬时心率 60*1000两个峰值的时间差
    int min_index_rl = minLeftMinIndex;
    if (minLeftTroughValue > minRightTroughValue) {
        min_index_rl = minRightMinIndex;
    }
    
    NSDictionary *first_point = self.points[minIndex];
    NSDictionary *second_point = self.points[min_index_rl];
    double first_time = [[[first_point allKeys] firstObject] doubleValue];
    double second_time = [[[second_point allKeys] firstObject] doubleValue];
    int fre = (int)((60 * 1000) / (first_time - second_time));
    fre = abs(fre);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.perMLabel.text = [NSString stringWithFormat:@"%d次/分钟",fre];
    });
    
    // 4.删除过去一个周期的数据
    for (int i = 0; i< self.T; i++) {
        [self.points removeObjectAtIndex:0];
    }
    
}

@end
