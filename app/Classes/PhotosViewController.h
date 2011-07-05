//
//  PhotosViewController.h
//  Noticings
//
//  Created by Tom Taylor on 09/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import "Photo.h"

@interface PhotosViewController : UITableViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate> 
{
	ALAssetsLibrary *assetsLibrary;
	NSMutableArray *photos;
	NSDateFormatter *timestampFormatter;
	BOOL photosLoaded;
	BOOL errorLoadingPhotos;
    UIBarButtonItem *cameraButton;
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
}

- (NSString *)formatDegrees:(CLLocationDegrees)locationDegrees;
- (void)loadPhotos;
- (void)displayPreviewForPhoto:(Photo *)photo;

@property (nonatomic, retain) CLLocation *currentLocation;

@end
