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

enum CameraControllerMode {
    CameraControllerCameraMode,
    CameraControllerSavedPhotosMode
};

@interface CameraController : NSObject <CLLocationManagerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate> 
{
    NSInteger mode;
}

- (void)presentImagePicker;
- (void)presentCamera;
- (id)initWithBaseViewController:(UIViewController *)baseViewController;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishTakingPhotoWithInfo:(NSDictionary *)info;
- (BOOL)cameraIsAvailable;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, strong) UIViewController *baseViewController;

@end
