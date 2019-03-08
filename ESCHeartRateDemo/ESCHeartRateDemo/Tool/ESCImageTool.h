//
//  ESCImageTool.h
//  ESCHeartRateDemo
//
//  Created by xiang on 2019/3/7.
//  Copyright © 2019 xiang. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESCImageTool : NSObject

+ (UIImage *)convert:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
