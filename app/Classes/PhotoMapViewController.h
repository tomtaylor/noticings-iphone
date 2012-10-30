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

@interface PhotoMapViewController : UIViewController <MKMapViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, CLLocationManagerDelegate> {
    UIBarButtonItem *uploadButton;
}

- (IBAction)adjustPin:(id)sender;
- (IBAction)mapTypeChanged;
- (void)promptForLocation;
- (void)currentLocationAlertViewClickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)previousLocationAlertViewClickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)noLocationAlertViewClickedButtonAtIndex:(NSInteger)buttonIndex;

@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *mapTypeControl;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) PhotoUpload *photoUpload;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocation *previousLocation;

@end
