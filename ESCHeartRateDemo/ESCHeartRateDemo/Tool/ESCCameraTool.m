//
//  ESCCameraTool.m
//  ESCHeartRateDemo
//
//  Created by xiang on 2019/3/7.
//  Copyright © 2019 xiang. All rights reserved.
//

#import "ESCCameraTool.h"

@interface ESCCameraTool ()

@property(nonatomic,strong)AVCaptureSession* captureSession;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property(nonatomic,strong)dispatch_queue_t videoDataOutputQueue;

@end

@implementation ESCCameraTool

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initCapureSession];
    }
    return self;
}

- (void)start {
    [self.captureSession startRunning];
}

- (void)stop {
    [self.captureSession stopRunning];
}

-(void)initCapureSession{
    //创建AVCaptureDevice的视频设备对象
    AVCaptureDevice* videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
  
    //创建视频输入端对象
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        NSLog(@"创建输入端失败,%@",error);
        return;
    }
    
    //创建功能会话对象
    self.captureSession = [[AVCaptureSession alloc] init];
    //设置会话输出的视频分辨率
    [self.captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    //添加输入端
    if (![self.captureSession canAddInput:input]) {
        NSLog(@"输入端添加失败");
        return;
    }
    [self.captureSession addInput:input];
    
    //显示摄像头捕捉到的数据
//    AVCaptureVideoPreviewLayer* layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
//    layer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 300);
//    [self.view.layer addSublayer:layer];
    
    //创建输出端
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    
    
    //会话对象添加输出端
    if ([self.captureSession canAddOutput:videoDataOutput]) {
        [self.captureSession addOutput:videoDataOutput];
        self.videoDataOutput = videoDataOutput;
        //创建输出调用的队列
        dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("videoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        self.videoDataOutputQueue = videoDataOutputQueue;
        //设置代理和调用的队列
        [self.videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
        //设置延时丢帧
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
        
        NSNumber *BGRA32PixelFormat = [NSNumber numberWithInt:kCVPixelFormatType_32BGRA];
        NSDictionary *rgbOutputSetting;
        rgbOutputSetting = [NSDictionary dictionaryWithObject:BGRA32PixelFormat
                                                       forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [videoDataOutput setVideoSettings:rgbOutputSetting];    //设置像素输出格式
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:didOutputSampleBuffer:fromConnection:)]) {
        [self.delegate captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection NS_AVAILABLE(10_7, 6_0) {
    if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:didDropSampleBuffer:fromConnection:)]) {
        [self.delegate captureOutput:output didDropSampleBuffer:sampleBuffer fromConnection:connection];
    }
}


@end
