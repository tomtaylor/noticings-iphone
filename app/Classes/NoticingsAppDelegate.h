//
//  NoticingsAppDelegate.h
//  Noticings
//
//  Created by Tom Taylor on 06/08/2009.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "FlickrAuthenticationViewController.h"
#import "CameraController.h"
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "ContactsStreamManager.h"
#import "CacheManager.h"
#import "UploadQueueManager.h"


@interface NoticingsAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate> {
	FlickrAuthenticationViewController *authViewController;
	UITabBarItem *queueTab;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet UIViewController *dummyViewController;
@property (nonatomic, retain) CameraController *cameraController;

@property (nonatomic, retain) IBOutlet UINavigationController *streamNavigationController;

@property (nonatomic, retain) ContactsStreamManager* contactsStreamManager;
@property (nonatomic, retain) CacheManager *cacheManager;
@property (nonatomic, retain) UploadQueueManager *uploadQueueManager;
@property (nonatomic, retain) DeferredFlickrCallManager *flickrCallManager;
@property (nonatomic, retain) PhotoLocationManager *photoLocationManager;

+(NoticingsAppDelegate*)delegate;

- (BOOL)isAuthenticated;


@end

