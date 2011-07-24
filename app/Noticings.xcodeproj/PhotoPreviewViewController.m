//
//  PhotoPreviewViewController.m
//  Noticings
//
//  Created by Tom Taylor on 05/05/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PhotoPreviewViewController.h"
#import "PhotoDetailViewController.h"
#import "PhotoUpload.h"

@implementation PhotoPreviewViewController

@synthesize imageView;

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
//    [super viewDidLoad];
//    
//    nextButton = [[UIBarButtonItem alloc] 
//                  initWithTitle:@"Next" 
//                  style:UIBarButtonSystemItemAction 
//                  target:self 
//                  action:@selector(nextPressed:)];    
//    [[self navigationItem] setRightBarButtonItem:nextButton];
//
//    
//    // allows us to use the space behind the status bar
//    self.wantsFullScreenLayout = YES;
//    
//    ALAssetRepresentation *defaultRepresentation = [photo.asset defaultRepresentation];
//    
//    CGImageRef imageRef = [defaultRepresentation fullScreenImage];
//    UIImage *image = [UIImage imageWithCGImage:imageRef 
//                                         scale:[defaultRepresentation scale] 
//                                   orientation:[defaultRepresentation orientation]];
//    imageView.image = image;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)nextPressed:(id)sender {
//    PhotoDetailViewController *photoDetailViewController = [[PhotoDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
//    PhotoUpload *photoUpload = [[PhotoUpload alloc] initWithPhoto:self.photo];
//    photoDetailViewController.photoUpload = photoUpload;
//    [self.navigationController pushViewController:photoDetailViewController animated:YES];
//    [photoUpload release];
//    [photoDetailViewController release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
