//
//  NoticingsAppDelegate.h
//  Noticings
//
//  Created by Tom Taylor on 06/08/2009.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "FlickrAuthenticationViewController.h"
#import "UploadQueueManager.h"
#import "CameraController.h"
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface NoticingsAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate> {
	UIWindow *window;
    UITabBarController *tabBarController;
	FlickrAuthenticationViewController *authViewController;
	UploadQueueManager *uploadQueueManager;
	UITabBarItem *queueTab;
    UIViewController *dummyViewController;
    CameraController *cameraController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet UIViewController *dummyViewController;
@property (nonatomic, retain) CameraController *cameraController;


@end

