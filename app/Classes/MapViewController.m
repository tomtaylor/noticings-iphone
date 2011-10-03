//
//  MapViewController.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "MapViewController.h"
#import "StreamPhotoViewController.h"
#import "RemoteImageView.h"

@implementation MapViewController

@synthesize mapView;
@synthesize photo;
@synthesize streamManager;

-(void)viewDidLoad;
{
    self.mapView = [[[MKMapView alloc] initWithFrame:self.view.bounds] autorelease];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES; // sure, why the hell not.

    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.autoresizesSubviews = YES;

    UIBarButtonItem *externalItem = [[UIBarButtonItem alloc] 
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                     target:self
                                     action:@selector(openInBrowser)];
    
    self.navigationItem.rightBarButtonItem = externalItem;
    [externalItem release];
    [self.view addSubview:self.mapView];
}

-(void)openInBrowser;
{
    [[UIApplication sharedApplication] openURL:photo.mapPageURL];
}

-(void)displayPhoto:(StreamPhoto*)_photo inManager:(PhotoStreamManager*)manager;
{
    self.photo = _photo;
    self.streamManager = manager;
    self.mapView.region = MKCoordinateRegionMake(photo.coordinate, MKCoordinateSpanMake(0.02, 0.02));
    for (StreamPhoto *p in manager.photos) {
        if (p.coordinate.latitude != 0 && p.coordinate.longitude != 0) {
            [self.mapView addAnnotation:p];
        }
    }
    [self performSelector:@selector(selectMainPhoto:) withObject:self.photo afterDelay:1.2];
}

-(void)selectMainPhoto:(StreamPhoto*)p;
{
    [self.mapView selectAnnotation:self.photo animated:YES];
}


- (MKAnnotationView *)mapView:(MKMapView *)sender viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *aView = [sender dequeueReusableAnnotationViewWithIdentifier:@"MyAnnotationView"];
    
    if (!aView) {
        aView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MyAnnotationView"] autorelease];
        aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        aView.leftCalloutAccessoryView = [[[RemoteImageView alloc] initWithFrame:CGRectMake(0,0,30,30)] autorelease];
        aView.canShowCallout = YES;
    }
    
    // imageURL is _way_ too big, but it has the advantage of probably already being cached
    if (annotation.class == StreamPhoto.class) {
        StreamPhoto *_photo = (StreamPhoto*)annotation;
        [((RemoteImageView *)aView.leftCalloutAccessoryView) loadURL:_photo.imageURL];
    } else {
        // TODO - this happens because the "you are here" point is an annotation. It shouldn't
        // get this popup at all, really.
    }
    aView.annotation = annotation; // this is the Photo object. Yay protocols.
    
    return aView;
}

- (void)mapView:(MKMapView *)sender annotationView:(MKAnnotationView *)aView calloutAccessoryControlTapped:(UIControl *)control;
{
    if (aView.annotation.class == StreamPhoto.class) {
        StreamPhotoViewController *vc = [[StreamPhotoViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
        vc.streamManager = self.streamManager;
        [vc showPhoto:photo];
        [vc release];
    }
}


- (void)dealloc;
{
    self.mapView.delegate = nil;
    self.mapView = nil;
    self.photo = nil;
    [super dealloc];
}


@end
