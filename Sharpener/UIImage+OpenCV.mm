//
//  UIImage+OpenCV.m
//  Sharpener
//
//  Created by Inti Guo on 1/26/16.
//  Copyright © 2016 Inti Guo. All rights reserved.
//

#import "UIImage+OpenCV.h"

@implementation UIImage (OpenCV)

- (cv::Mat)cvMat {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(self.CGImage);
    CGFloat cols = self.size.width;
    CGFloat rows = self.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,     // Pointer to data
                                                    cols,           // Width of bitmap
                                                    rows,           // Height of bitmap
                                                    8,              // Bits per component
                                                    cvMat.step[0],  // Bytes per row
                                                    colorSpace,     // Color space
                                                    kCGImageAlphaNoneSkipLast
                                                    | kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), self.CGImage);
    CGContextRelease(contextRef);
    return cvMat;
}

+ (UIImage *)UIImageFromCVMat:(cv::Mat)mat {
    NSData *data = [NSData dataWithBytes:mat.data length:mat.elemSize()*mat.total()];
    
    CGColorSpaceRef colorspace;
    
    if (mat.elemSize() == 1) {
        colorspace = CGColorSpaceCreateDeviceGray();
    }else{
        colorspace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // create CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(mat.cols, mat.rows, 8, 8 * mat.elemSize(), mat.step[0], colorspace, kCGImageAlphaNone | kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    
    // get UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorspace);
    return finalImage;
}

@end
