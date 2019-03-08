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

static double T = 10;
// 是否是停顿状态
static bool is_wait = NO;

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *perMLabel;

@property(nonatomic,strong)ESCCameraTool* cameratool;

@property(nonatomic,assign)BOOL isRecording;

@property(nonatomic,weak)ESCHeartRateView* heartRateView;

@property(nonatomic,strong)NSMutableArray* points;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
//    NSLog(@"did get %@",output);
    
    /** 读取图像Buffer */
    CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    uint8_t*buf = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    
    NSInteger totalR = 0;
    NSInteger totalG = 0;
    NSInteger totalB = 0;
    
    for (int i = 0; i < height * width; i++) {
        int b = buf[i * 4];
        int g = buf[i * 4 + 1];
        int r = buf[i * 4 + 2];
        totalR += r;
        totalG += g;
        totalB += b;
    }
    
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    double averageR = totalR * 1.0 / (width * height);
    double averageG = totalG * 1.0 / (width * height);
    double averageB = totalB * 1.0 / (width * height);
    double H = [ESCColorTool getHFromR:averageR g:averageG b:averageB];
//    NSLog(@"%lf==",H);
    H = HeartRate(H);
//    NSLog(@"%lf",H);
    if (is_wait == YES) {
        return;
    }
    if (H >= 1.0 || H <= -1.0 ) {
        count = 0;
        lastH = 0;
        [self.points removeAllObjects];
        is_wait = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            is_wait = NO;
        });
        return;
        
    }
    [self.heartRateView addValue:H];
    double t = [[NSDate date] timeIntervalSince1970]*1000;
    NSDictionary *point = @{[NSNumber numberWithDouble:t]:[NSNumber numberWithFloat:H]};
    [self analysisPointsWith:point];
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 6_0) {
    NSLog(@"did drop %@",output);
}
// 记录浮点变化的前一次的值
static float lastH = 0;
// 用于判断是否是第一个福点值
static int   count = 0;
float HeartRate (float h) {
    float low = 0;
    count++;
    lastH = (count==1)?h:lastH;
    low = (h-lastH);
    lastH = h;
    return low;
}

- (void)analysisPointsWith:(NSDictionary *)point {
    
    [self.points addObject:point];
    if (self.points.count <= 30){
        return;
    }
    int count = (int)self.points.count;
    
    if (self.points.count % 10 == 0) {
        
        int d_i_c = 0;          //最低峰值的位置 姑且算在中间位置 c->center
        int d_i_l = 0;          //最低峰值左面的最低峰值位置 l->left
        int d_i_r = 0;          //最低峰值右面的最低峰值位置 r->right
        
        
        float trough_c = 0;     //最低峰值的浮点值
        float trough_l = 0;     //最低峰值左面的最低峰值浮点值
        float trough_r = 0;     //最低峰值右面的最低峰值浮点值
        
        // 1.先确定数据中的最低峰值
        for (int i = 0; i < count; i++) {
            float trough = [[[self.points[i] allObjects] firstObject] floatValue];
            if (trough < trough_c) {
                trough_c = trough;
                d_i_c = i;
            }
        }
        
        // 2.找到最低峰值以后  以最低峰值为中心 找到前0.5-1.5周期中的最低峰值  和后0.5-1.5周期的最低峰值
        
        if (d_i_c >= 1.5 * T) {
            
            // a.如果最低峰值处在中心位置， 即距离前后都至少有1.5个周期
            if (d_i_c <= count-1.5*T) {
                // 左面最低峰值
                for (int j = d_i_c - 0.5*T; j > d_i_c - 1.5*T; j--) {
                    float trough = [[[self.points[j] allObjects] firstObject] floatValue];
                    if (trough < trough_l) {
                        trough_l = trough;
                        d_i_l = j;
                    }
                }
                // 右面最低峰值
                for (int k = d_i_c + 0.5*T; k < d_i_c + 1.5*T; k++) {
                    float trough = [[[self.points[k] allObjects] firstObject] floatValue];
                    if (trough < trough_r) {
                        trough_r = trough;
                        d_i_r = k;
                    }
                }
                
            }
            // b.如果最低峰值右面不够1.5个周期 分两种情况 不够0.5个周期和够0.5个周期
            else {
                // b.1 够0.5个周期
                if (d_i_c <count-0.5*T) {
                    // 左面最低峰值
                    for (int j = d_i_c - 0.5*T; j > d_i_c - 1.5*T; j--) {
                        float trough = [[[self.points[j] allObjects] firstObject] floatValue];
                        if (trough < trough_l) {
                            trough_l = trough;
                            d_i_l = j;
                        }
                    }
                    // 右面最低峰值
                    for (int k = d_i_c + 0.5*T; k < count; k++) {
                        float trough = [[[self.points[k] allObjects] firstObject] floatValue];
                        if (trough < trough_r) {
                            trough_r = trough;
                            d_i_r = k;
                        }
                    }
                }
                // b.2 不够0.5个周期
                else {
                    // 左面最低峰值
                    for (int j = d_i_c - 0.5*T; j > d_i_c - 1.5*T; j--) {
                        float trough = [[[self.points[j] allObjects] firstObject] floatValue];
                        if (trough < trough_l) {
                            trough_l = trough;
                            d_i_l = j;
                        }
                    }
                }
            }
            
        }
        // c. 如果左面不够1.5个周期 一样分两种情况  够0.5个周期 不够0.5个周期
        else {
            // c.1 够0.5个周期
            if (d_i_c>0.5*T) {
                // 左面最低峰值
                for (int j = d_i_c - 0.5*T; j > 0; j--) {
                    float trough = [[[self.points[j] allObjects] firstObject] floatValue];
                    if (trough < trough_l) {
                        trough_l = trough;
                        d_i_l = j;
                    }
                }
                // 右面最低峰值
                for (int k = d_i_c + 0.5*T; k < d_i_c + 1.5*T; k++) {
                    float trough = [[[self.points[k] allObjects] firstObject] floatValue];
                    if (trough < trough_r) {
                        trough_r = trough;
                        d_i_r = k;
                    }
                }
                
            }
            // c.2 不够0.5个周期
            else {
                // 右面最低峰值
                for (int k = d_i_c + 0.5*T; k < d_i_c + 1.5*T; k++) {
                    float trough = [[[self.points[k] allObjects] firstObject] floatValue];
                    if (trough < trough_r) {
                        trough_r = trough;
                        d_i_r = k;
                    }
                }
            }
            
        }
        
        // 3. 确定哪一个与最低峰值更接近 用最接近的一个最低峰值测出瞬时心率 60*1000两个峰值的时间差
        if (trough_l-trough_c < trough_r-trough_c) {

            NSDictionary *point_c = self.points[d_i_c];
            NSDictionary *point_l = self.points[d_i_l];
            double t_c = [[[point_c allKeys] firstObject] doubleValue];
            double t_l = [[[point_l allKeys] firstObject] doubleValue];
            NSInteger fre = (NSInteger)(60*1000)/(t_c - t_l);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.perMLabel.text = [NSString stringWithFormat:@"%ld次/分钟",fre];
            });
        } else {
            NSDictionary *point_c = self.points[d_i_c];
            NSDictionary *point_r = self.points[d_i_r];
            double t_c = [[[point_c allKeys] firstObject] doubleValue];
            double t_r = [[[point_r allKeys] firstObject] doubleValue];
            NSInteger fre = (NSInteger)(60*1000)/(t_r - t_c);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.perMLabel.text = [NSString stringWithFormat:@"%ld次/分钟",fre];
            });
        }
        // 4.删除过期数据
        for (int i = 0; i< 10; i++) {
            [self.points removeObjectAtIndex:0];
        }
    }
}

@end
