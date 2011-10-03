//
//  StreamPhotoViewController.m
//  Noticings
//
//  Created by Tom Insam on 30/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "StreamPhotoViewController.h"
#import "StreamPhotoViewCell.h"
#import "UserStreamManager.h"
#import "ImageViewController.h"
#import "MapViewController.h"
#import "StreamViewController.h"
#import "PhotoLocationManager.h"

@implementation StreamPhotoViewController

@synthesize photo, streamManager, photoLocation;

-(id)init;
{
    self = [super initWithNibName:@"StreamPhotoViewController" bundle:nil];
    if (self) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPhoto:)];
        tap.numberOfTouchesRequired = 1;
        [self.view addGestureRecognizer:tap];
        [tap release];
    }
    return self;
}

-(CGFloat)flow:(UIView*)aView from:(CGFloat)y resize:(BOOL)resize;
{
    CGRect frame = aView.frame;
    frame.origin.y = y;
    aView.frame = frame;
    if (resize)
        [aView sizeToFit];
    return y + aView.frame.size.height + PADDING_SIZE;
}


-(void)showPhoto:(StreamPhoto*)_photo;
{
    self.photo = _photo;
    
    usernameView.text = self.photo.ownername;

    if (self.photo.hasLocation) {
        self.photoLocation = self.photo.placename;
        [[PhotoLocationManager sharedPhotoLocationManager] getLocationForPhoto:photo and:^(NSString* name){
            if (name) {
                self.photoLocation = name;
                [self updateHTML];
            }
        }];

    }

    titleView.text = self.photo.title;
    [self updateHTML];
    [photoView loadURL:self.photo.imageURL];
    [avatarView loadURL:self.photo.avatarURL];
    
    // resize image frame to have the right aspect.
    CGRect frame = photoView.frame;
    CGFloat height = [photo imageHeightForWidth:frame.size.width];
    frame.size.height = height;
    photoView.frame = frame;
    
    CGFloat y = photoView.frame.origin.y + photoView.frame.size.height + PADDING_SIZE;

    if (self.photo.hasLocation) {
        y = [self flow:mapView from:y resize:NO];
        [mapView loadURL:self.photo.mapImageURL];
    } else {
        mapView.frame = CGRectMake(0, 0, 0, 0);
    }

    y = [self flow:descView from:y resize:YES];
    
    theView.frame = CGRectMake(0, 0, 320, y);
    
    UIScrollView *scrollView = (UIScrollView*)self.view;
    [scrollView addSubview:theView];
    scrollView.contentSize = CGSizeMake(theView.frame.size.width, y);
    scrollView.alwaysBounceVertical = YES;
}

-(void)updateHTML;
{
    // beginning to want an actual templating language here. :-)
    
    // Load common HTML heading. TODO - maybe cache as static string, it's a little
    // wasteful to load this all the time?
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"StreamPhotoViewController" ofType:@"html" inDirectory:nil];
    NSString *html = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    
    // Visibility
    NSString *visClass = @"public";
    NSString *visName = @"public";
    if (self.photo.visibility == StreamPhotoVisibilityPrivate) {
        visClass = @"private";
        visName = @"private";
    } else if (self.photo.visibility == StreamPhotoVisibilityLimited) {
        visClass = @"limited";
        visName = @"friends and family only";
    }
    html = [html stringByAppendingFormat:@"<p class='%@'>Photo is %@.</p>", visClass, visName];

    // Time ago
    html = [html stringByAppendingFormat:@"<p class='timeago'>Taken %@ ago", self.photo.ago];

    // location (in same paragraph)
    if (self.photo.hasLocation) {
        html = [html stringByAppendingFormat:@", in <a href='%@'>%@</a>", self.photo.mapPageURL, self.photoLocation]; // TODO - html escape!
    }
    html = [html stringByAppendingString:@".</p>"];

    // description
    if (self.photo.html) {
        html = [html stringByAppendingFormat:@"<p class='description'>%@</p>", self.photo.html];
    }

    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    [descView loadHTMLString:html baseURL:baseURL];
}

// open links in the webview using the system browser
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return false;
    }
    return true;
}

- (void)tapPhoto:(UIGestureRecognizer*)tap;
{
    CGPoint tapPoint = [tap locationInView:self.view];
    UIView *hit = [self.view hitTest:tapPoint withEvent:nil];

    if ([hit isEqual:photoView]) {
        ImageViewController *imageViewController = [[ImageViewController alloc] init];
        [self.navigationController pushViewController:imageViewController animated:YES];
        [imageViewController displayPhoto:self.photo];
        [imageViewController release];

    } else if ([hit isEqual:mapView]) {
        MapViewController *mapController = [[MapViewController alloc] init];
        [self.navigationController pushViewController:mapController animated:YES];
        [mapController displayPhoto:photo inManager:self.streamManager];
        [mapController release];

    } else if ([hit isEqual:avatarView]) {
        UserStreamManager *manager = [[UserStreamManager alloc] initWithUser:photo.ownerId];
        StreamViewController *userController = [[StreamViewController alloc] initWithPhotoStreamManager:manager];
        [manager release];
        userController.title = photo.ownername;
        [self.navigationController pushViewController:userController animated:YES];
        [userController release];
    }
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
