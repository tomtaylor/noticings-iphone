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

@interface PhotosViewController : UITableViewController {
	ALAssetsLibrary *assetsLibrary;
	NSMutableArray *photos;
	NSDateFormatter *timestampFormatter;
	BOOL photosLoaded;
	BOOL errorLoadingPhotos;
}

- (NSString *)formatDegrees:(CLLocationDegrees)locationDegrees;
- (void)loadPhotos;

@end
