//
//  ESCCameraTool.h
//  ESCHeartRateDemo
//
//  Created by xiang on 2019/3/7.
//  Copyright © 2019 xiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESCCameraTool : NSObject

@property(nonatomic,weak)id<AVCaptureVideoDataOutputSampleBufferDelegate> delegate;;

- (void)start;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
