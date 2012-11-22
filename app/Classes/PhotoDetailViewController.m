//
//  PhotoDetailViewController.m
//  Noticings
//
//  Created by Tom Taylor on 11/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoDetailViewController.h"
#import "EditableTextFieldCell.h"
#import "PhotoMapViewController.h"
#import "UploadTimestampViewController.h"
#import <MapKit/MapKit.h>
#import "StreamViewController.h"
#import "NoticingsAppDelegate.h"

@implementation PhotoDetailViewController

-(id)initWithPhotoUpload:(PhotoUpload*)upload;
{
    self = [super initWithNibName:@"PhotoDetailViewController" bundle:nil];
    if (self != nil) {
        self.photoUpload = upload;
        
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Details";
	
	UIBarButtonItem *nextButton = [[UIBarButtonItem alloc]
								   initWithTitle:@"Upload"
								   style:UIBarButtonItemStylePlain
								   target:self
								   action:@selector(next)];
	
	[[self navigationItem] setRightBarButtonItem:nextButton];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] 
                                     initWithTitle:@"Cancel" 
                                     style:UIBarButtonItemStylePlain 
                                     target:self 
                                     action:@selector(cancel)];
    [[self navigationItem] setLeftBarButtonItem:cancelButton];


    UITapGestureRecognizer* tapRec = [[UITapGestureRecognizer alloc]
                                      initWithTarget:self action:@selector(didTapMap:)];
    [self.mapView addGestureRecognizer:tapRec];
    
    self.thumbnailView.image = self.photoUpload.thumbnail;

    // TODO hilariously inefficient
    int bytes = [self.photoUpload imageData].length;
    self.detailText.text = [NSString stringWithFormat:@"%uk (%0.0f x %0.0f)", bytes / 1024, self.photoUpload.image.size.width, self.photoUpload.image.size.height];

}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateStyle:NSDateFormatterNoStyle];
    self.defaultTitle = [dateFormatter stringFromDate:[self.photoUpload timestamp]];
	self.photoTitle.placeholder = [NSString stringWithFormat:@"Title (default %@)", self.defaultTitle];

    [self.mapView removeAnnotations:self.mapView.annotations];
	CLLocationCoordinate2D coordinate = self.photoUpload.coordinate;
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        self.mapView.region = MKCoordinateRegionMakeWithDistance(coordinate, 1500, 1500);
        [self.mapView addAnnotation:self.photoUpload];
        self.mapView.alpha = 1;
    } else {
        self.mapView.region = MKCoordinateRegionForMapRect(MKMapRectWorld);
        self.mapView.alpha = 0.3;
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
//    // If the user just pressed 'next' on the keyboard from the title cell, then jump to showing the tags cell. Otherwise, close the keyboard.
//	if ([textField isEqual:self.photoTitle]) {
//		[self.photoTags becomeFirstResponder];
//	} else {
//        [textField resignFirstResponder];
//        return NO;
//	}
//	return YES;
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (IBAction)didTapMap:(id)sender;
{
    DLog(@"tapped map");
    PhotoMapViewController *mapViewController = [[PhotoMapViewController alloc] init];
    mapViewController.photoUpload = self.photoUpload;
    [self.navigationController pushViewController:mapViewController animated:YES];
}

- (void)next {
	self.photoUpload.title = [self.photoTitle.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	self.photoUpload.tags = self.photoTags.text;
    
    if (self.photoUpload.title.length == 0) {
        self.photoUpload.title = self.defaultTitle;
    }
	
	if (self.photoUpload.timestamp == nil) {
        self.photoUpload.timestamp = [NSDate date];
    }

    [[NoticingsAppDelegate delegate].uploadQueueManager addPhotoUploadToQueue:self.photoUpload];
    [[AppDelegate tabBarController] setSelectedIndex:0];
    [self.navigationController dismissModalViewControllerAnimated:YES];

    // pop the photos view back to the main list, and scroll that to the top so we see the upload progress
    UINavigationController *firstNavController = [[AppDelegate tabBarController] viewControllers][0];
    [firstNavController popToRootViewControllerAnimated:NO];
    StreamViewController *streamView = (StreamViewController*)(firstNavController.viewControllers)[0];
    [streamView.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)cancel {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)privacyChanged:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.photoUpload.privacy = PhotoUploadPrivacyPrivate;
            break;
        case 1:
            self.photoUpload.privacy = PhotoUploadPrivacyFriendsAndFamily;
            break;
        case 2:
            self.photoUpload.privacy = PhotoUploadPrivacyPublic;
        default:
            break;
    }
}

@end

