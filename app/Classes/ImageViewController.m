//
//  ImageViewController.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "ImageViewController.h"

@implementation ImageViewController

#define ZOOM_STEP 3

@synthesize photo;
@synthesize scrollView;
@synthesize imageView;

-(void)viewDidLoad;
{
    self.scrollView = [[[UIScrollView alloc] initWithFrame:self.view.bounds] autorelease];
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 20;
    self.scrollView.delegate = self;
    self.scrollView.bouncesZoom = YES;
    self.scrollView.bounces = YES;
    
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.autoresizesSubviews = YES;

    self.imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 1024, 1024 * (480.0f/320))] autorelease];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.scrollView addSubview:self.imageView];
    self.scrollView.contentSize = self.imageView.frame.size;

    // gesture management
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    [twoFingerTap setNumberOfTouchesRequired:2];
    [self.scrollView addGestureRecognizer:doubleTap];
    [self.scrollView addGestureRecognizer:twoFingerTap];
    [doubleTap release];
    [twoFingerTap release];
    
    UIBarButtonItem *externalItem = [[UIBarButtonItem alloc] 
        initWithBarButtonSystemItem:UIBarButtonSystemItemAction
        target:self
        action:@selector(openInBrowser)];

    self.navigationItem.rightBarButtonItem = externalItem;
    [externalItem release];
    [self.view addSubview:self.scrollView];
}

-(void)openInBrowser;
{
    [[UIApplication sharedApplication] openURL:photo.originalImageURL];
}

-(void)displayPhoto:(StreamPhoto*)_photo;
{
    self.photo = _photo;
    // ask for the big one first. if it's in the cache, it'll load, and we'll refuse to load
    // the smaller one later. otherwise, the smaller one will almost certainly be either already
    // in the cache, or load faster.
    //
    // Explicitly _don't_ load the original. Some of those are insane, and you're probably using
    // the wrong app if you care about them.
    //
    // Defer this to the next iteration of the runloop, so that we have a view
    // already set up, or the scaling goes squiffy.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[CacheManager sharedCacheManager] fetchImageForURL:self.photo.bigImageURL andNotify:self];
        [[CacheManager sharedCacheManager] fetchImageForURL:self.photo.imageURL andNotify:self];
    }];
}

-(void)loadedImage:(UIImage *)image forURL:(NSURL*)url cached:(BOOL)cached;
{
    NSLog(@"Loaded image %fx%f from %@", image.size.width, image.size.height, url);
    
    if (self.imageView.image) {
        // image is already loaded. is this onr better?
        if (image.size.width <= self.imageView.image.size.width && image.size.height <= self.imageView.image.size.height) {
            NSLog(@"refusing to use a lower-resolution image.");
            return;
        }
    }
    
    // snap back out to full zoom before loading, or sometihng odd happens with the extents.
    self.scrollView.zoomScale = 1;

    self.imageView.image = image;
    self.imageView.frame = self.view.frame;
    self.scrollView.contentSize = self.imageView.frame.size;

    // knock the zoom level in a tiny tiny bit so we get bouncy edges to the scroll view.
    self.scrollView.zoomScale = 1.001;
}


// based on http://developer.apple.com/library/ios/#samplecode/ScrollViewSuite/Listings/1_TapToZoom_Classes_RootViewController_m.html#//apple_ref/doc/uid/DTS40008904-1_TapToZoom_Classes_RootViewController_m-DontLinkElementID_6

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // the zoom rect is in the content view's coordinates. 
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = [self.scrollView frame].size.height / scale;
    zoomRect.size.width  = [self.scrollView frame].size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}


- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer {
    NSLog(@"double-tap");
    // double tap zooms in
    float newScale = [self.scrollView zoomScale] * ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gestureRecognizer locationInView:self.imageView]];
    [self.scrollView zoomToRect:zoomRect animated:YES];
}

- (void)handleTwoFingerTap:(UIGestureRecognizer *)gestureRecognizer {
    NSLog(@"2-finger tap");
    // two-finger tap zooms out
    float newScale = [self.scrollView zoomScale] / ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gestureRecognizer locationInView:self.imageView]];
    [self.scrollView zoomToRect:zoomRect animated:YES];
}



- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
}

-(void)dealloc;
{
    NSLog(@"deallocing %@", self.class);
    self.scrollView.delegate = nil;
    self.scrollView = nil;
    self.imageView = nil;
    self.photo = nil;
    [super dealloc];
}


@end
