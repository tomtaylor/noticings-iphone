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
    //core data
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

// core data
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
- (NSString *)applicationDocumentsDirectory;
- (void)savePersistentObjects;

// interfaceb uilder
@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, strong) IBOutlet UIViewController *dummyViewController;
@property (nonatomic, strong) CameraController *cameraController;
@property (nonatomic, strong) IBOutlet UINavigationController *streamNavigationController;

@property (nonatomic, strong) FlickrAuthenticationViewController *authViewController;
@property (nonatomic, strong) UITabBarItem *queueTab;

// API managers
@property (nonatomic, strong) ContactsStreamManager* contactsStreamManager;
@property (nonatomic, strong) CacheManager *cacheManager;
@property (nonatomic, strong) UploadQueueManager *uploadQueueManager;
@property (nonatomic, strong) DeferredFlickrCallManager *flickrCallManager;
@property (nonatomic, strong) PhotoLocationManager *photoLocationManager;

+ (NoticingsAppDelegate*)delegate;

@property (nonatomic, readonly) BOOL isAuthenticated;


#define PHOTO_CHANGED_NOTIFICATION @"photo_changed_notification"




// log only in dev
#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

// throws up an alert box in dev
#ifdef DEBUG
#   define ULog(fmt, ...)  { UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%s\n [Line %d] ", __PRETTY_FUNCTION__, __LINE__] message:[NSString stringWithFormat:fmt, ##__VA_ARGS__]  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil]; [alert show]; }
#else
#   define ULog(...)
#endif

// always log
#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);


#ifdef TESTFLIGHT
#   define RLog(fmt, ...) NSLog((@"%@ %s [Line %d] " fmt), self, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define RLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#endif



@end
