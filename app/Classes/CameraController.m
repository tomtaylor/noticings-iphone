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
#import "UIImage+Resize.h"

@interface CameraController (Private)

- (NSDictionary *)gpsDictionaryForCurrentLocation;

@end

@implementation CameraController

- (id)initWithBaseViewController:(UIViewController *)baseViewController {
    self = [super init];
    if (self) {
        CLLocationManager *aLocationManager = [[CLLocationManager alloc] init];
        aLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
        aLocationManager.delegate = self;
        self.locationManager = aLocationManager;
        
        ALAssetsLibrary *anAssetsLibrary = [[ALAssetsLibrary alloc] init];
        self.assetsLibrary = anAssetsLibrary;
        
        self.baseViewController = baseViewController;
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
        // use ALAssetLibrary so we can get the GPS information from the photo
        NSURL *assetUrl = info[UIImagePickerControllerReferenceURL];
        DLog(@"Reading asset with URL: %@", assetUrl);
        [self.assetsLibrary assetForURL:assetUrl 
                       resultBlock:^(ALAsset *asset) {
                           DLog(@"Loaded Asset: %@", asset);
                           UIImage *image = [[UIImage alloc] initWithCGImage:asset.defaultRepresentation.fullResolutionImage];
                           CLLocation* location = [asset valueForProperty:ALAssetPropertyLocation];
                           NSDate* timestamp = [asset valueForProperty:ALAssetPropertyDate];
                           PhotoUpload *photoUpload = [[PhotoUpload alloc] initWithImage:image location:location timestamp:timestamp];
                           PhotoDetailViewController *photoDetailViewController = [[PhotoDetailViewController alloc] initWithPhotoUpload:photoUpload];
                           
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
        // TODO why does this work? not mutable?
        [metadata setValue:gpsMetadata forKey:(NSString *)kCGImagePropertyGPSDictionary];
    }
    
    // TODO - resizing should be option
    UIImage *resizedImage = [originalImage resizedImageWithWidth:1200 AndHeight:1200];

    // save the image to camera roll (TODO make optional) but I really don't care beyond this point
    [self.assetsLibrary writeImageToSavedPhotosAlbum:resizedImage.CGImage
                                            metadata:metadata
                                     completionBlock:nil];
    
    PhotoUpload *photoUpload = [[PhotoUpload alloc] initWithImage:resizedImage
                                                         location:self.currentLocation
                                                        timestamp:[NSDate date]
                                ];
    PhotoDetailViewController *photoDetailViewController = [[PhotoDetailViewController alloc] initWithPhotoUpload:photoUpload];
    
    UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:photoDetailViewController];
    
    [self.baseViewController dismissModalViewControllerAnimated:NO];
    [self.baseViewController presentModalViewController:detailNavigationController animated:NO];

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.locationManager stopUpdatingLocation];
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

- (BOOL)cameraIsAvailable
{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (void)dealloc {
    if (self.locationManager) {
        self.locationManager.delegate = nil;
        [self.locationManager stopUpdatingLocation];
    }
}

@end
