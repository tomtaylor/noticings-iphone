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
#import "DeferredFlickrCallManager.h"

#import "NSString+HTML.h"

@implementation StreamPhotoViewController

@synthesize photo, streamManager, photoLocation, webView;

-(id)init;
{
    self = [super initWithNibName:nil bundle:nil];
    return self;
}

-(void)loadView;
{
    [super loadView];
}

-(void)viewDidLoad;
{
    self.webView = [[[UIWebView alloc] initWithFrame:self.view.bounds] autorelease];
    self.webView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.autoresizesSubviews = YES;
    [self.view addSubview:self.webView];
}

-(void)showPhoto:(StreamPhoto*)_photo;
{
    self.photo = _photo;
    self.title = self.photo.title; // for nav controller
    
    if (self.photo.hasLocation) {
        self.photoLocation = self.photo.placename;
        [[PhotoLocationManager sharedPhotoLocationManager] getLocationForPhoto:photo and:^(NSString* name){
            if (name) {
                self.photoLocation = name;
                [self updateHTML];
            }
        }];
    }
    
    [[CacheManager sharedCacheManager] fetchImageForURL:photo.imageURL andNotify:self];

    if (self.photo.hasLocation) {
        [[CacheManager sharedCacheManager] fetchImageForURL:photo.mapImageURL andNotify:self];
    }

    [self updateHTML];
}

-(void)loadedImage:(UIImage *)image cached:(BOOL)cached;
{
    NSLog(@"loaded image");
    [self updateHTML];
}


-(void)updateHTML;
{
    CacheManager *cacheManager = [CacheManager sharedCacheManager];
    
    // beginning to want an actual templating language here. :-)
    
    // Load common HTML heading. TODO - maybe cache as static string, it's a little
    // wasteful to load this all the time?
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"StreamPhotoViewController" ofType:@"html" inDirectory:nil];
    NSString *htmlWrapper = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    
    NSString *html = @"";
    
    html = [html stringByAppendingFormat:@"<a href='noticings-image:nil'><img class='image' src='%@'></a>", [cacheManager urlToFilename:photo.imageURL]];

    html = [html stringByAppendingFormat:@"<a href='noticings-user:nil'><img class='avatar' src='%@'></a>", [cacheManager urlToFilename:photo.avatarURL]];

    html = [html stringByAppendingFormat:@"<p class='title'>%@</p>", [photo.title stringByEncodingHTMLEntities]];

    html = [html stringByAppendingFormat:@"<p class='owner'>by <a href='noticings-user:nil'>%@</a></p>", [photo.ownername stringByEncodingHTMLEntities]];

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

    html = [html stringByAppendingString:@"<div style='clear: both'></div>"];

    // Time ago
    html = [html stringByAppendingFormat:@"<p class='timeago'>Taken %@ ago", [self.photo.ago stringByEncodingHTMLEntities]];

    // location (in same paragraph)
    if (self.photo.hasLocation) {
        html = [html stringByAppendingFormat:@", in <a href='noticings-map:nil'>%@</a>:</p>", [self.photoLocation stringByEncodingHTMLEntities]];
        html = [html stringByAppendingFormat:@"<a href='noticings-map:nil'><img class='map' src='%@'></a>", [cacheManager urlToFilename:photo.mapImageURL]];
    } else {
        html = [html stringByAppendingString:@".</p>"];
    }

    // description
    if (self.photo.html) {
        html = [html stringByAppendingFormat:@"<p class='description'>%@</p>", self.photo.html];
    }

    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    [self.webView loadHTMLString:[NSString stringWithFormat:htmlWrapper, html] baseURL:baseURL];
}

// open links in the webview using the system browser
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"should start load %@", request);
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {

        if ([request.URL.scheme isEqualToString:@"noticings-image"]) {
            ImageViewController *imageViewController = [[ImageViewController alloc] init];
            [self.navigationController pushViewController:imageViewController animated:YES];
            [imageViewController displayPhoto:self.photo];
            [imageViewController release];
            return false;

        } else if ([request.URL.scheme isEqualToString:@"noticings-map"]) {
            MapViewController *mapController = [[MapViewController alloc] init];
            [self.navigationController pushViewController:mapController animated:YES];
            [mapController displayPhoto:photo inManager:self.streamManager];
            [mapController release];
            return false;

        } else if ([request.URL.scheme isEqualToString:@"noticings-user"]) {
            UserStreamManager *manager = [[UserStreamManager alloc] initWithUser:photo.ownerId];
            StreamViewController *userController = [[StreamViewController alloc] initWithPhotoStreamManager:manager];
            [manager release];
            userController.title = photo.ownername;
            [self.navigationController pushViewController:userController animated:YES];
            [userController release];
            return false;
        }

        [[UIApplication sharedApplication] openURL:request.URL];
        return false;
    }
    NSLog(@"allowing through load request %@", request);
    return true;
}

//- (void)tapPhoto:(UIGestureRecognizer*)tap;
//{
//    CGPoint tapPoint = [tap locationInView:self.view];
//    UIView *hit = [self.view hitTest:tapPoint withEvent:nil];
//
//    if ([hit isEqual:photoView]) {
//
//    } else if ([hit isEqual:mapView]) {
//
//    } else if ([hit isEqual:avatarView]) {
//    }
//    
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.webView.delegate = nil;
    self.webView = nil;
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)dealloc;
{
    if (self.webView) {
        self.webView.delegate = nil;
    }
    self.webView = nil;
    [super dealloc];
}


@end
