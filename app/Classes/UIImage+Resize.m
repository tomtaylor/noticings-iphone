//
//  UIImage+Resize.m
//  Noticings
//
//  Created by Tom Insam on 2012/11/21.
//
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

- (UIImage *)resizedImageWithWidth:(CGFloat)maxWidth AndHeight:(CGFloat)maxHeight {
	CGFloat targetWidth;
	CGFloat targetHeight;
	
    CGImageRef sourceRef = self.CGImage;
	CGFloat width = CGImageGetWidth(sourceRef);
	CGFloat height = CGImageGetHeight(sourceRef);
	
	if ((width == maxWidth && height <= maxHeight) || (width <= maxWidth && height == maxHeight)){
		// the source image already has the exact target size (one dimension is equal and one is less)
		return [self copy];
	} else { // picture must be resized
        // The biggest ratio (ratioWidth, ratioHeight) will tell us which side should be the max side
		CGFloat ratioWidth = width / maxWidth;
		CGFloat ratioHeight = height / maxHeight;
		if (ratioWidth > ratioHeight) {
			targetWidth = maxWidth;
			targetHeight = height / ratioWidth;
		}
		else {
			targetHeight = maxHeight;
			targetWidth = width / ratioHeight;
		}
	}
	
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(sourceRef);
	CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(sourceRef);
	
	if (bitmapInfo == kCGImageAlphaNone) {
		bitmapInfo = kCGImageAlphaNoneSkipLast;
	}
	
	size_t bitesPerComponent = CGImageGetBitsPerComponent(sourceRef);
	// To know the "bitesPerRow", we multiply the number of bits of a component per pixel (a component = Green for instance), 4 (RGB + alpha) and the row length (targetWidth)
	size_t bitesPerRow = bitesPerComponent * 4 * targetWidth;
	
	
	CGContextRef bitmap;
    bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, bitesPerComponent, bitesPerRow, colorSpaceInfo, bitmapInfo);
    
	CGContextDrawImage(bitmap, CGRectMake(0, 0, targetWidth, targetHeight), sourceRef);
	CGImageRef resizedImage = CGBitmapContextCreateImage(bitmap);
	CGContextRelease(bitmap);
    
    UIImage *resized = [UIImage imageWithCGImage:resizedImage scale:1 orientation:self.imageOrientation];
    CGImageRelease(resizedImage);
    
	return resized;
}

- (UIImage *)resizedSquareImageWithSize:(CGFloat)thumbSize;
{
	// Create a thumbnail version of the image for the event object.
	CGSize size = self.size;
	CGSize croppedSize;
	CGFloat offsetX = 0.0;
	CGFloat offsetY = 0.0;
    
	// check the size of the image, we want to make it
	// a square with sides the size of the smallest dimension
	if (size.width > size.height) {
		offsetX = (size.height - size.width) / 2;
		croppedSize = CGSizeMake(size.height, size.height);
	} else {
		offsetY = (size.width - size.height) / 2;
		croppedSize = CGSizeMake(size.width, size.width);
	}
    
	// Crop the image before resize
	CGRect clippedRect = CGRectMake(offsetX * -1, offsetY * -1, croppedSize.width, croppedSize.height);
	CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], clippedRect);
	// Done cropping
    
	// Resize the image
	CGRect rect = CGRectMake(0.0, 0.0, thumbSize, thumbSize);
    
	UIGraphicsBeginImageContext(rect.size);
	[[UIImage imageWithCGImage:imageRef scale:1 orientation:self.imageOrientation] drawInRect:rect];
	UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	// Done Resizing
    
	return thumbnail;
}

@end


