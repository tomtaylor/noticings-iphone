//
//  CameraController.h
//  Noticings
//
//  Created by Tom Taylor on 18/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>

@interface CameraController : NSObject <CLLocationManagerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate> 
{
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    ALAssetsLibrary *assetsLibrary;
    UITabBarController *tabBarController;
}

- (void)presentImagePicker;
- (id)initWithTabBarController:(UITabBarController *)tabBarController;

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *currentLocation;
@property (nonatomic, retain) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, retain) UITabBarController *tabBarController;

@end
