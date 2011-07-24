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
@synthesize tabBarController;

- (id)initWithTabBarController:(UITabBarController *)_tabBarController {
    self = [super init];
    if (self) {
        CLLocationManager *aLocationManager = [[CLLocationManager alloc] init];
        aLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
        aLocationManager.delegate = self;
        self.locationManager = aLocationManager;
        [aLocationManager release];
        
        ALAssetsLibrary *anAssetsLibrary = [[ALAssetsLibrary alloc] init];
        self.assetsLibrary = anAssetsLibrary;
        [anAssetsLibrary release];
        
        self.tabBarController = _tabBarController;
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
    NSMutableDictionary *gps = [NSMutableDictionary dictionary];
    
    // GPS tag version
    [gps setObject:@"2.2.0.0" forKey:(NSString *)kCGImagePropertyGPSVersion];
    
    // Time and date must be provided as strings, not as an NSDate object
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss.SSSSSS"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [gps setObject:[formatter stringFromDate:self.currentLocation.timestamp] forKey:(NSString *)kCGImagePropertyGPSTimeStamp];
    [formatter setDateFormat:@"yyyy:MM:dd"];
    [gps setObject:[formatter stringFromDate:self.currentLocation.timestamp] forKey:(NSString *)kCGImagePropertyGPSDateStamp];
    [formatter release];
    
    // Latitude
    CGFloat latitude = self.currentLocation.coordinate.latitude;
    if (latitude < 0) {
        latitude = -latitude;
        [gps setObject:@"S" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    } else {
        [gps setObject:@"N" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    }
    [gps setObject:[NSNumber numberWithFloat:latitude] forKey:(NSString *)kCGImagePropertyGPSLatitude];
    
    // Longitude
    CGFloat longitude = self.currentLocation.coordinate.longitude;
    if (longitude < 0) {
        longitude = -longitude;
        [gps setObject:@"W" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    } else {
        [gps setObject:@"E" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    }
    [gps setObject:[NSNumber numberWithFloat:longitude] forKey:(NSString *)kCGImagePropertyGPSLongitude];
    
    // Altitude
    CGFloat altitude = self.currentLocation.altitude;
    if (!isnan(altitude)) {
        if (altitude < 0) {
            altitude = -altitude;
            [gps setObject:@"1" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        } else {
            [gps setObject:@"0" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        }
        [gps setObject:[NSNumber numberWithFloat:altitude] forKey:(NSString *)kCGImagePropertyGPSAltitude];
    }
    
    // Speed, must be converted from m/s to km/h
    if (self.currentLocation.speed >= 0) {
        [gps setObject:@"K" forKey:(NSString *)kCGImagePropertyGPSSpeedRef];
        [gps setObject:[NSNumber numberWithFloat:self.currentLocation.speed*3.6] forKey:(NSString *)kCGImagePropertyGPSSpeed];
    }
    
    // Heading
    if (self.currentLocation.course >= 0) {
        [gps setObject:@"T" forKey:(NSString *)kCGImagePropertyGPSTrackRef];
        [gps setObject:[NSNumber numberWithFloat:self.currentLocation.course] forKey:(NSString *)kCGImagePropertyGPSTrack];
    }
    
    return gps;
}

#pragma mark UIImagePickerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //[self.tabBarController dismissModalViewControllerAnimated:NO];
    [self.locationManager stopUpdatingLocation];
    
    DLog(@"metadata: %@", info);
    
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSDictionary *metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
    
    // GPS isn't recorded unless we do it manually
    NSDictionary *gpsMetadata = [self gpsDictionaryForCurrentLocation];
    [metadata setValue:gpsMetadata forKey:(NSString *)kCGImagePropertyGPSDictionary];
    
    CGImageRef cgImage = [originalImage CGImage];
    
    [assetsLibrary 
     writeImageToSavedPhotosAlbum:cgImage
     metadata:metadata 
     completionBlock:^(NSURL *assetURL, NSError *error) {
         if (error) {
             DLog(@"Failed to write Asset: %@", error);
         } else {
             [assetsLibrary 
              assetForURL:assetURL 
              resultBlock:^(ALAsset *asset) {
                  DLog(@"Asset written to URL: %@", assetURL);
                  PhotoUpload *photoUpload = [[PhotoUpload alloc] initWithAsset:asset];
                  PhotoDetailViewController *photoDetailViewController = [[PhotoDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
                  photoDetailViewController.photoUpload = photoUpload;
                  
                  UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:photoDetailViewController];
                  [self.tabBarController dismissModalViewControllerAnimated:NO];
                  [self.tabBarController presentModalViewController:detailNavigationController animated:NO];
                  
                  [photoUpload release];
                  [photoDetailViewController release];
                  [detailNavigationController release];
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

- (void)presentImagePicker
{
    [self.locationManager startUpdatingLocation];
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self.tabBarController presentModalViewController:imagePickerController 
                                             animated:YES];
    [imagePickerController release];
}

- (void)dealloc {
    locationManager.delegate = nil;
    [locationManager release];
    [assetsLibrary release];
    [tabBarController release];
    [super dealloc];
}

@end
