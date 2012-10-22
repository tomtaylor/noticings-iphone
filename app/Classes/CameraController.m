//
//  CameraController.m
//  Noticings
//
//  Created by Tom Taylor on 18/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CameraController.h"
#import "PhotoUpload.h"
#import "PhotoDetailViewController.h"
#import <ImageIO/ImageIO.h>

@interface CameraController (Private)

- (NSDictionary *)gpsDictionaryForCurrentLocation;

@end

@implementation CameraController

@synthesize locationManager;
@synthesize currentLocation;
@synthesize assetsLibrary;
@synthesize baseViewController;

- (id)initWithBaseViewController:(UIViewController *)_baseViewController {
    self = [super init];
    if (self) {
        CLLocationManager *aLocationManager = [[CLLocationManager alloc] init];
        aLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
        aLocationManager.delegate = self;
        self.locationManager = aLocationManager;
        
        ALAssetsLibrary *anAssetsLibrary = [[ALAssetsLibrary alloc] init];
        self.assetsLibrary = anAssetsLibrary;
        
        self.baseViewController = _baseViewController;
    }
    return self;
}

#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager 
    didUpdateToLocation:(CLLocation *)newLocation 
           fromLocation:(CLLocation *)oldLocation
{
    // we'll take any location in the last 2 minutes
    if (abs([newLocation.timestamp timeIntervalSinceDate: [NSDate date]]) < 120) 
    {
		self.currentLocation = newLocation;
		DLog(@"Location updated to: %@", newLocation);
	}
}

- (void)locationManager:(CLLocationManager *)manager 
       didFailWithError:(NSError *)error
{
    
}

- (NSDictionary *)gpsDictionaryForCurrentLocation {    
    if (!self.currentLocation) {
        return nil;
    }
    
    NSMutableDictionary *gps = [NSMutableDictionary dictionary];

    // GPS tag version
    gps[(NSString *)kCGImagePropertyGPSVersion] = @"2.2.0.0";
    
    // Time and date must be provided as strings, not as an NSDate object
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss.SSSSSS"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    gps[(NSString *)kCGImagePropertyGPSTimeStamp] = [formatter stringFromDate:self.currentLocation.timestamp];
    [formatter setDateFormat:@"yyyy:MM:dd"];
    gps[(NSString *)kCGImagePropertyGPSDateStamp] = [formatter stringFromDate:self.currentLocation.timestamp];
    
    // Latitude
    CGFloat latitude = self.currentLocation.coordinate.latitude;
    if (latitude < 0) {
        latitude = -latitude;
        gps[(NSString *)kCGImagePropertyGPSLatitudeRef] = @"S";
    } else {
        gps[(NSString *)kCGImagePropertyGPSLatitudeRef] = @"N";
    }
    gps[(NSString *)kCGImagePropertyGPSLatitude] = @(latitude);
    
    // Longitude
    CGFloat longitude = self.currentLocation.coordinate.longitude;
    if (longitude < 0) {
        longitude = -longitude;
        gps[(NSString *)kCGImagePropertyGPSLongitudeRef] = @"W";
    } else {
        gps[(NSString *)kCGImagePropertyGPSLongitudeRef] = @"E";
    }
    gps[(NSString *)kCGImagePropertyGPSLongitude] = @(longitude);
    
    // Altitude
    CGFloat altitude = self.currentLocation.altitude;
    if (!isnan(altitude)) {
        if (altitude < 0) {
            altitude = -altitude;
            gps[(NSString *)kCGImagePropertyGPSAltitudeRef] = @"1";
        } else {
            gps[(NSString *)kCGImagePropertyGPSAltitudeRef] = @"0";
        }
        gps[(NSString *)kCGImagePropertyGPSAltitude] = @(altitude);
    }
    
    // Speed, must be converted from m/s to km/h
    if (self.currentLocation.speed >= 0) {
        gps[(NSString *)kCGImagePropertyGPSSpeedRef] = @"K";
        gps[(NSString *)kCGImagePropertyGPSSpeed] = [NSNumber numberWithFloat:3.6f * self.currentLocation.speed];
    }
    
    // Heading
    if (self.currentLocation.course >= 0) {
        gps[(NSString *)kCGImagePropertyGPSTrackRef] = @"T";
        gps[(NSString *)kCGImagePropertyGPSTrack] = [NSNumber numberWithFloat:self.currentLocation.course];
    }
    return gps;
}

#pragma mark UIImagePickerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (mode == CameraControllerCameraMode) {
        [self imagePickerController:picker didFinishTakingPhotoWithInfo:info];
    } else {
        [self.baseViewController dismissModalViewControllerAnimated:NO];
        NSURL *assetUrl = info[UIImagePickerControllerReferenceURL];
        DLog(@"Reading asset with URL: %@", assetUrl);
        [self.assetsLibrary assetForURL:assetUrl 
                       resultBlock:^(ALAsset *asset) {
                           DLog(@"Loaded Asset: %@", asset);
                           PhotoUpload *photoUpload = [[PhotoUpload alloc] initWithAsset:asset];
                           PhotoDetailViewController *photoDetailViewController = [[PhotoDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
                           photoDetailViewController.photoUpload = photoUpload;
                           
                           UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:photoDetailViewController];
                           
                           [self.baseViewController dismissModalViewControllerAnimated:NO];
                           [self.baseViewController.navigationController presentModalViewController:detailNavigationController animated:NO];
                       }
                      failureBlock:^(NSError *error) {
                          DLog(@"Failed to get Asset by URL: %@", error);
                      }];
    }

}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishTakingPhotoWithInfo:(NSDictionary *)info
{
    [self.locationManager stopUpdatingLocation];
    
    DLog(@"metadata: %@", info);
    
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    NSDictionary *metadata = info[UIImagePickerControllerMediaMetadata];
    
    // GPS isn't recorded unless we do it manually
    NSDictionary *gpsMetadata = [self gpsDictionaryForCurrentLocation];
    
    if (gpsMetadata) {
        [metadata setValue:gpsMetadata forKey:(NSString *)kCGImagePropertyGPSDictionary];
    }
    
    CGImageRef cgImage = [originalImage CGImage];
    CGImageRef resizedImage = [self resizedImage:cgImage withWidth:1200.0f AndHeight:1200.0f];
    
    [self.assetsLibrary 
     writeImageToSavedPhotosAlbum:resizedImage
     metadata:metadata 
     completionBlock:^(NSURL *assetURL, NSError *error) {
         if (error) {
             DLog(@"Failed to write Asset: %@", error);
         } else {
             DLog(@"Asset written to URL: %@", assetURL);
             [assetsLibrary 
              assetForURL:assetURL 
              resultBlock:^(ALAsset *asset) {
                  DLog(@"Asset read from URL: %@", assetURL);
                  PhotoUpload *photoUpload = [[PhotoUpload alloc] initWithAsset:asset];
                  PhotoDetailViewController *photoDetailViewController = [[PhotoDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
                  photoDetailViewController.photoUpload = photoUpload;
                  
                  UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:photoDetailViewController];
                  
                  [self.baseViewController dismissModalViewControllerAnimated:NO];
                  [self.baseViewController presentModalViewController:detailNavigationController animated:NO];
              }
              failureBlock:^(NSError *error) {
                  DLog(@"Failed to get Asset by URL: %@", error);
              }
              ];
         }
     }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [locationManager stopUpdatingLocation];
    [picker dismissModalViewControllerAnimated:YES];
}

- (void)presentCamera
{
    mode = CameraControllerCameraMode;
    [self.locationManager startUpdatingLocation];
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self.baseViewController presentModalViewController:imagePickerController 
                                             animated:YES];
}

- (void)presentImagePicker
{
    mode = CameraControllerSavedPhotosMode;
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self.baseViewController presentModalViewController:imagePickerController 
                                               animated:YES];
}

- (CGImageRef)resizedImage:(CGImageRef)sourceImage withWidth:(CGFloat)maxWidth AndHeight:(CGFloat)maxHeight {
	CGFloat targetWidth;
	CGFloat targetHeight;
	
	CGFloat width = CGImageGetWidth(sourceImage);
	CGFloat height = CGImageGetHeight(sourceImage);
	
	if ((width == maxWidth && height <= maxHeight) || (width <= maxWidth && height == maxHeight)){
		// the source image already has the exact target size (one dimension is equal and one is less)
		return sourceImage;
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
	
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(sourceImage);
	CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(sourceImage);
	
	if (bitmapInfo == kCGImageAlphaNone) {
		bitmapInfo = kCGImageAlphaNoneSkipLast;
	}
	
	size_t bitesPerComponent = CGImageGetBitsPerComponent(sourceImage);
	// To know the "bitesPerRow", we multiply the number of bits of a component per pixel (a component = Green for instance), 4 (RGB + alpha) and the row length (targetWidth)
	size_t bitesPerRow = bitesPerComponent * 4 * targetWidth;
	
	
	CGContextRef bitmap;
    bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, bitesPerComponent, bitesPerRow, colorSpaceInfo, bitmapInfo);

	CGContextDrawImage(bitmap, CGRectMake(0, 0, targetWidth, targetHeight), sourceImage);
	CGImageRef resizedImage = CGBitmapContextCreateImage(bitmap);
	CGContextRelease(bitmap);
    
    // return an autoreleased CGImage
    if (resizedImage) {
        // TODO
//        resizedImage = (CGImageRef)[[(id)CFBridgingRelease(resizedImage) retain] autorelease];
//        CGImageRelease(resizedImage);
    }
    
	return resizedImage;
}

- (BOOL)cameraIsAvailable
{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (void)dealloc {
    if (locationManager) {
        locationManager.delegate = nil;
        [locationManager stopUpdatingLocation];
    }
}

@end
