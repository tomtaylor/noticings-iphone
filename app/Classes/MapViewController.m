//
//  MapViewController.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "MapViewController.h"
#import "ImageViewController.h"

@implementation MapViewController

@synthesize mapView;
@synthesize photo;

-(void)loadView;
{
    self.mapView = [[[MKMapView alloc] initWithFrame:CGRectNull] autorelease];
    self.view = self.mapView;
    self.mapView.delegate = self;
}

-(void)displayPhoto:(StreamPhoto*)_photo;
{
    self.photo = _photo;
    self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(photo.latitude, photo.longitude), MKCoordinateSpanMake(0.02, 0.02));
    [self.mapView addAnnotation:self.photo];
    self.mapView.showsUserLocation = YES; // why the hell not.
}

- (MKAnnotationView *)mapView:(MKMapView *)sender viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *aView = [sender dequeueReusableAnnotationViewWithIdentifier:@"MyAnnotationView"];
    
    if (!aView) {
        aView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MyAnnotationView"] autorelease];
        aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        // TODO - tiny thumbnail of the photo here would be awesome.
        //aView.leftCalloutAccessoryView = [[[UIImageView alloc] initWithFrame:CGRectMake(0,0,30,30)] autorelease];
        aView.canShowCallout = YES;
    }
    
    //((UIImageView *)aView.leftCalloutAccessoryView).image = nil;
    aView.annotation = annotation;
    
    return aView;
}

- (void)mapView:(MKMapView *)sender annotationView:(MKAnnotationView *)aView calloutAccessoryControlTapped:(UIControl *)control;
{
    ImageViewController *imageViewController = [[ImageViewController alloc] init];
    [self.navigationController pushViewController:imageViewController animated:YES];
    [imageViewController displayPhoto:photo];
    [imageViewController release];
}


- (void)dealloc;
{
    self.mapView.delegate = nil;
    self.mapView = nil;
    self.photo = nil;
    [super dealloc];
}


@end
