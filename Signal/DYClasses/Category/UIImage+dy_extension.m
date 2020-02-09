//
//  UIImage+dy_extension.m
//  Project
//
//  Created by fangyuan on 2019/8/15.
//  Copyright © 2019 CDJay. All rights reserved.
//

#import "UIImage+dy_extension.h"

@implementation UIImage (dy_extension)

+ (UIImage*)imageWithColor:(UIColor*)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)dy_circleImageWithColor:(UIColor *)color size:(CGFloat)size {
    
    CGRect rect = CGRectMake(0.0f, 0.0f, size, size);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
   
    CGContextAddEllipseInRect(context, rect);
    CGContextClip(context);
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
    
    
}

+ (UIImage *)dy_circleImageWithColor:(UIColor *)color size:(CGFloat)size attribute:(NSAttributedString *)attr {
    
    CGRect rect = CGRectMake(0.0f, 0.0f, size, size);
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 2.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    

    CGContextAddEllipseInRect(context, rect);
    CGContextClip(context);
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    CGFloat margin  = 7;
    NSDictionary *dict = [attr attributesAtIndex:0 effectiveRange:nil];
    if (dict[NSFontAttributeName]) {
        UIFont *font = dict[NSFontAttributeName];
        margin = font.pointSize * 0.5;
    }
    if (attr) {
        [attr drawAtPoint:CGPointMake(size * 0.5 - margin, size * 0.5 - margin)];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
     
     return image;
    
    
}

- (UIImage *)dy_rotateImageWithAngle:(CGFloat)angle resize:(CGSize)size {
    
    if (!self.CGImage) return nil;
    size_t width = size.width;
    size_t height = size.height;
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0., 0., width, height),
                                                CGAffineTransformMakeRotation(angle));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)newRect.size.width,
                                                 (size_t)newRect.size.height,
                                                 8,
                                                 (size_t)newRect.size.width * 4,
                                                 colorSpace,
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;
    
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGContextTranslateCTM(context, +(newRect.size.width * 0.5), +(newRect.size.height * 0.5));
    CGContextRotateCTM(context, angle);
    
    CGContextDrawImage(context, CGRectMake(-(width * 0.5), -(height * 0.5), width, height), self.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
#if SD_UIKIT || SD_WATCH
    UIImage *img = [UIImage imageWithCGImage:imgRef scale:self.scale orientation:self.imageOrientation];
#else
    UIImage *img = [[UIImage alloc] initWithCGImage:imgRef scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
    CGImageRelease(imgRef);
    CGContextRelease(context);
    
    return img;
}



- (void)detectorQRImageWithFinished:(void (^)(NSArray<CIQRCodeFeature *> * _Nullable, NSError * _Nullable))finished {
    
    // CIDetector(CIDetector可用于人脸识别)进行图片解析，从而使我们可以便捷的从相册中获取到二维码
    // 声明一个 CIDetector，并设定识别类型 CIDetectorTypeText
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    UIImage *image = [[UIImage alloc] initWithCGImage:self.CGImage];

    if (!image) {
        NSError *error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:-1001 userInfo:@{NSNetServicesErrorDomain : @"不支持的图片格式"}];
        finished(nil, error);
        return;
    }

    
    // 取得识别结果
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    
    if (features.count == 0) {
        NSError *error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:-1002 userInfo:@{NSNetServicesErrorDomain : @"未能识别图中的二维码"}];
              finished(nil, error);
        
    } else {
        for (int index = 0; index < [features count]; index ++) {
            
            CIQRCodeFeature *feature = [features objectAtIndex:index];
            NSLog(@"读取二维码数据信息 - - %@",            @(feature.bounds));
            NSLog(@"读取二维码数据信息2 - - %@",            feature.messageString);
        }
        finished(features, nil);
    }
    
    
}
@end
