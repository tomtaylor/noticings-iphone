//
//  PhotoMapViewController.h
//  Noticings
//
//  Created by Tom Taylor on 13/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "PhotoUpload.h"

@interface PhotoMapViewController : UIViewController <MKMapViewDelegate, UIActionSheetDelegate, CLLocationManagerDelegate> {
	PhotoUpload *photoUpload;
	IBOutlet MKMapView *mapView;
	IBOutlet UISegmentedControl *mapTypeControl;
	IBOutlet UIToolbar *toolbar;
	CLLocationManager *locationManager;
	CLLocation *currentLocation;
}

- (IBAction)moveTo:(id)sender;
- (IBAction)mapTypeChanged;

@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *mapTypeControl;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) PhotoUpload *photoUpload;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *currentLocation;

@end
