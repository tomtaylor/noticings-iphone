//
//  MapViewController.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "MapViewController.h"
#import "StreamPhotoViewController.h"

@implementation MapViewController

@synthesize mapView;
@synthesize photo;
@synthesize streamManager;

-(void)viewDidLoad;
{
    self.mapView = [[[MKMapView alloc] initWithFrame:self.view.bounds] autorelease];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = NO;
    
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.autoresizesSubviews = YES;
    [self.view addSubview:self.mapView];
    
    // button in top-right to open maps app.
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
                                               initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                               target:self
                                               action:@selector(externalButton)]
                                              autorelease];
}

-(void)externalButton;
{
    UIActionSheet *popupQuery = [[UIActionSheet alloc]
                                 initWithTitle:@"Open location"
                                 delegate:self
                                 cancelButtonTitle:nil
                                 destructiveButtonTitle:nil
                                 otherButtonTitles:nil];
    [popupQuery addButtonWithTitle:@"Open in Maps"];
    popupQuery.cancelButtonIndex = [popupQuery addButtonWithTitle:@"Cancel"];
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [popupQuery showFromTabBar:self.tabBarController.tabBar];
    [popupQuery release];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [[UIApplication sharedApplication] openURL:photo.mapPageURL];
    }
}

-(void)displayPhoto:(StreamPhoto*)_photo inManager:(PhotoStreamManager*)manager;
{
    self.photo = _photo;
    self.streamManager = manager;
    self.mapView.region = MKCoordinateRegionMake(photo.coordinate, MKCoordinateSpanMake(0.03, 0.03));
    [self.mapView addAnnotation:self.photo];
    [self performSelector:@selector(selectPhoto:) withObject:self.photo afterDelay:2];
}

-(void)selectPhoto:(StreamPhoto*)p;
{
    [self.mapView selectAnnotation:p animated:YES];
}


- (MKAnnotationView *)mapView:(MKMapView *)theMap viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *aView = [theMap dequeueReusableAnnotationViewWithIdentifier:@"PhotoAnnotation"];
    
    if (!aView) {
        aView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"PhotoAnnotation"] autorelease];
        aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        aView.canShowCallout = YES;
    }
    
    aView.annotation = annotation; // this is the Photo object. Yay protocols.
    
    return aView;
}

- (void)mapView:(MKMapView *)sender annotationView:(MKAnnotationView *)aView calloutAccessoryControlTapped:(UIControl *)control;
{
    if (aView.annotation.class == StreamPhoto.class) {
        [self externalButton];
    }
}


- (void)dealloc;
{
    self.mapView.delegate = nil;
    self.mapView = nil;
    self.photo = nil;
    self.streamManager = nil;
    [super dealloc];
}


@end
