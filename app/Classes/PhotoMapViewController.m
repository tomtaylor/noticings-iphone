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

@implementation PhotoMapViewController

@synthesize mapView;
@synthesize mapTypeControl;
@synthesize photoUpload;
@synthesize toolbar;
@synthesize locationManager;
@synthesize currentLocation;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	locationManager.distanceFilter = kCLDistanceFilterNone;
	[self.locationManager startUpdatingLocation];
	
	self.title = @"Location";
	
	UIBarButtonItem *uploadButton = [[UIBarButtonItem alloc] 
								   initWithTitle:@"Upload" 
								   style:UIBarButtonItemStyleDone
								   target:self
								   action:@selector(upload)];
	
	[[self navigationItem] setRightBarButtonItem:uploadButton];
	[uploadButton release];
		
	CLLocationCoordinate2D coordinate = self.photoUpload.coordinate;
	
	if (!CLLocationCoordinate2DIsValid(coordinate)) {
		coordinate.latitude = [[NSUserDefaults standardUserDefaults] floatForKey:@"lastKnownLatitude"];
		coordinate.longitude = [[NSUserDefaults standardUserDefaults] floatForKey:@"lastKnownLongitude"];
		[self.photoUpload setCoordinate:coordinate];
		[[[[UIAlertView alloc] initWithTitle:@"No location found" 
									 message:@"This photo was saved without a location, so we've set it to the position of the last photo you uploaded."
									delegate:nil
						   cancelButtonTitle:@"OK" 
						   otherButtonTitles:nil] autorelease] show];
	} else {
		[[NSUserDefaults standardUserDefaults] setFloat:coordinate.latitude forKey:@"lastKnownLatitude"];
		[[NSUserDefaults standardUserDefaults] setFloat:coordinate.longitude forKey:@"lastKnownLongitude"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, 500, 500);
	self.mapView.showsUserLocation = NO;
	[self.mapView addAnnotation:self.photoUpload];

//	
//	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"firstMapViewComplete"]) {
//		[[[[UIAlertView alloc] initWithTitle:@"Adjusting the location"
//									 message:@"You can hold and drag the pin to adjust the location of your photo."
//									delegate:nil
//						   cancelButtonTitle:@"OK" 
//						   otherButtonTitles:nil] autorelease] show];
//		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstMapViewComplete"];
//	}
}


#pragma mark -
#pragma mark MKMapViewDelegate methods

- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
	if (annotation == mapView.userLocation) {
		return nil;
	}
	
	MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"Pin"];
	if (annotationView == nil) {
		annotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pin"] autorelease];
	}
	
	annotationView.pinColor = MKPinAnnotationColorPurple;
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
	if ([UploadQueueManager sharedUploadQueueManager].inProgress == NO) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
}

- (void)locationManager:(CLLocationManager *)manager 
	didUpdateToLocation:(CLLocation *)newLocation 
		   fromLocation:(CLLocation *)oldLocation
{
	if (abs([newLocation.timestamp timeIntervalSinceDate: [NSDate date]]) < 300) {
		self.currentLocation = newLocation;
		NSLog(@"Location updated to: %@", newLocation);
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)upload {
	CLLocationCoordinate2D coordinate = self.photoUpload.coordinate;
	[[NSUserDefaults standardUserDefaults] setFloat:coordinate.latitude forKey:@"lastKnownLatitude"];
	[[NSUserDefaults standardUserDefaults] setFloat:coordinate.longitude forKey:@"lastKnownLongitude"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[[UploadQueueManager sharedUploadQueueManager] addPhotoUploadToQueue:self.photoUpload];
	[[UploadQueueManager sharedUploadQueueManager] startQueueIfNeeded];
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)moveTo:(id)sender {
	NSLog(@"Button pressed");
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Move pin to" 
														delegate:self 
											   cancelButtonTitle:@"Cancel" 
										  destructiveButtonTitle:nil 
											   otherButtonTitles:@"Original location", @"Current location", nil];
	
	[sheet showFromToolbar:toolbar];
	[sheet release];
}

- (IBAction)mapTypeChanged {
	switch (mapTypeControl.selectedSegmentIndex) {
		case 0:
			mapView.mapType = MKMapTypeStandard;
			break;
		case 1:
			mapView.mapType = MKMapTypeHybrid;
			break;
		case 2:
			mapView.mapType = MKMapTypeSatellite;
			break;
		default:
			break;
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case 0:
			if (self.photoUpload.photo.location) {
				self.photoUpload.coordinate = self.photoUpload.photo.location.coordinate;
				[mapView setCenterCoordinate:self.photoUpload.coordinate animated:YES];
			} else {
				[[[[UIAlertView alloc] initWithTitle:@"Original Location Not Found" 
											 message:@"This photo wasn't saved with a location."
											delegate:nil
								   cancelButtonTitle:@"OK" 
								   otherButtonTitles:nil] autorelease] show];
			}
			
			break;
		case 1:
			if (currentLocation) {
				self.photoUpload.coordinate = currentLocation.coordinate;
				[mapView setCenterCoordinate:self.photoUpload.coordinate animated:YES];
			} else {
				[[[[UIAlertView alloc] initWithTitle:@"No Location Found" 
											 message:@"Your device's location couldn't be found."
											delegate:nil
								   cancelButtonTitle:@"OK" 
								   otherButtonTitles:nil] autorelease] show];
			}
			break;
		default:
			break;
	}
}

- (void)dealloc {
	[locationManager stopUpdatingLocation];
	locationManager.delegate = nil;
	[locationManager release];
	[currentLocation release];
	mapView.delegate = nil;
	[photoUpload release];
    [super dealloc];
}


@end
