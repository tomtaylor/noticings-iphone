//
//  PhotoMapViewController.m
//  Noticings
//
//  Created by Tom Taylor on 13/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoMapViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "UploadQueueManager.h"
#import "NoticingsAppDelegate.h"
#import "StreamViewController.h"

enum {
    kUIAlertViewCurrentLocation,
    kUIAlertViewPreviousLocation,
    kUIAlertViewNoLocation
};

@implementation PhotoMapViewController

static NSString *adjustPinActionSheetCancelTitle = @"Cancel";
static NSString *adjustPinActionSheetOriginalLocationTitle = @"Original Location";
static NSString *adjustPinActionSheetCurrentLocationTitle = @"Current Location";
static NSString *adjustPinActionSheetPreviousLocationTitle = @"Last Uploaded Location";
static NSString *adjustPinActionSheetRemoveTitle = @"Remove from Map";
static NSString *adjustPinActionSheetAddTitle = @"Add to Map";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapView.showsUserLocation = NO;
	
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
	self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	self.locationManager.distanceFilter = kCLDistanceFilterNone;
	[self.locationManager startUpdatingLocation];
	
	self.title = @"Location";
	
	CLLocationCoordinate2D coordinate = self.photoUpload.coordinate;
    
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, 500, 500);
        [self.mapView addAnnotation:self.photoUpload];
    } else {
        self.mapView.region = MKCoordinateRegionForMapRect(MKMapRectWorld);
        // give it a second to get a location from the locationmanager, before popping the dialog
        //[self performSelector:@selector(adjustPin:) withObject:nil afterDelay:2.0f];
    }
}

#pragma mark -
#pragma mark MKMapViewDelegate methods

- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
	if (annotation == self.mapView.userLocation) {
		return nil;
	}
	
	MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"Pin"];
	if (annotationView == nil) {
		annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pin"];
	}
	
	annotationView.pinColor = MKPinAnnotationColorRed;
	annotationView.animatesDrop = YES;
	annotationView.canShowCallout = NO;
	annotationView.draggable = YES;
	[annotationView setSelected:YES animated:NO];
	
	return annotationView;
}

- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)locationManager:(CLLocationManager *)manager 
	didUpdateToLocation:(CLLocation *)newLocation 
		   fromLocation:(CLLocation *)oldLocation
{
    // we remember the first location we get back from this, regardless of how old it might be
    if (self.previousLocation == nil) {
        self.previousLocation = newLocation;
        DLog(@"Setting previous location to: %@", self.previousLocation);
    }
    
	if (abs([newLocation.timestamp timeIntervalSinceDate: [NSDate date]]) < 120) {
		self.currentLocation = newLocation;
		DLog(@"Location updated to: %@", newLocation);
	}
}

-(void)viewWillDisappear:(BOOL)animated;
{
    [super viewWillDisappear:animated];
	CLLocationCoordinate2D coordinate = self.photoUpload.coordinate;
    
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        [[NSUserDefaults standardUserDefaults] setFloat:coordinate.latitude forKey:@"lastKnownLatitude"];
        [[NSUserDefaults standardUserDefaults] setFloat:coordinate.longitude forKey:@"lastKnownLongitude"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)adjustPin:(id)sender {
    if (self.view == nil) {
        return;
    }

    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Adjust Pin"
                                                       delegate:self 
                                              cancelButtonTitle:adjustPinActionSheetCancelTitle
                                         destructiveButtonTitle:nil 
                                              otherButtonTitles:nil];

    if ([self.mapView.annotations containsObject:self.photoUpload]) {
        [sheet addButtonWithTitle:adjustPinActionSheetRemoveTitle];
    } else {
        [sheet addButtonWithTitle:adjustPinActionSheetAddTitle];
    }

    if (CLLocationCoordinate2DIsValid(self.photoUpload.originalCoordinate)) {
        [sheet addButtonWithTitle:adjustPinActionSheetOriginalLocationTitle];
    }
    
    if (self.currentLocation) {
        [sheet addButtonWithTitle:adjustPinActionSheetCurrentLocationTitle];
    }
    
    if (self.previousLocation) {
        [sheet addButtonWithTitle:adjustPinActionSheetPreviousLocationTitle];
    }
	
	[sheet showFromToolbar:self.toolbar];
}

- (IBAction)mapTypeChanged {
	switch (self.mapTypeControl.selectedSegmentIndex) {
		case 0:
			self.mapView.mapType = MKMapTypeStandard;
			break;
		case 1:
			self.mapView.mapType = MKMapTypeHybrid;
			break;
		case 2:
			self.mapView.mapType = MKMapTypeSatellite;
			break;
		default:
			break;
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        // don't re-display pin
        return;
    }

    if ([buttonTitle isEqualToString:adjustPinActionSheetOriginalLocationTitle]) {
        self.photoUpload.coordinate = self.photoUpload.originalCoordinate;
        
    } else if ([buttonTitle isEqualToString:adjustPinActionSheetCurrentLocationTitle]) {
        self.photoUpload.coordinate = self.currentLocation.coordinate;
        
    } else if ([buttonTitle isEqualToString:adjustPinActionSheetPreviousLocationTitle]) {
        self.photoUpload.coordinate = self.previousLocation.coordinate;
        
    } else if ([buttonTitle isEqualToString:adjustPinActionSheetAddTitle]) {
        self.photoUpload.coordinate = [self.mapView centerCoordinate];
        
    } else if ([buttonTitle isEqualToString:adjustPinActionSheetRemoveTitle]) {
        self.photoUpload.coordinate = kCLLocationCoordinate2DInvalid;
        
    }
    
    [self.mapView removeAnnotations:self.mapView.annotations];
	CLLocationCoordinate2D coordinate = self.photoUpload.coordinate;
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(self.photoUpload.coordinate, 500, 500) animated:YES];
        [self.mapView addAnnotation:self.photoUpload];
    }
}

- (void)dealloc {
	[self.locationManager stopUpdatingLocation];
}


@end
