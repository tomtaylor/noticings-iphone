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
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    ALAssetsLibrary *assetsLibrary;
    UIViewController *baseViewController;
    NSInteger mode;
}

- (void)presentImagePicker;
- (void)presentCamera;
- (id)initWithBaseViewController:(UIViewController *)baseViewController;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishTakingPhotoWithInfo:(NSDictionary *)info;
- (CGImageRef)resizedImage:(CGImageRef)sourceImage withWidth:(CGFloat)maxWidth AndHeight:(CGFloat)maxHeight;

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *currentLocation;
@property (nonatomic, retain) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, retain) UIViewController *baseViewController;

@end
