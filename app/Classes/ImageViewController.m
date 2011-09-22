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

-(void)loadView;
{
    self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)] autorelease];
    self.scrollView.backgroundColor = [UIColor grayColor];
    self.scrollView.maximumZoomScale = 10;
    self.scrollView.minimumZoomScale = 0.1;
    self.scrollView.delegate = self;

    self.imageView = [[[UIImageView alloc] initWithFrame:CGRectNull] autorelease];
    [self.scrollView addSubview:self.imageView];

    self.view = self.scrollView;

    
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
}

-(void)openInBrowser;
{
    [[UIApplication sharedApplication] openURL:photo.mobilePageURL];
    
}

-(void)displayPhoto:(StreamPhoto*)_photo;
{
    self.photo = _photo;
    [[CacheManager sharedCacheManager] fetchImageForURL:self.photo.imageURL andNotify:self];
}

-(void)loadedImage:(UIImage *)image cached:(BOOL)cached;
{
    NSLog(@"Loaded image %fx%f", image.size.width, image.size.height);
    
    if (self.imageView.image) {
        // image is already loaded. is this onr better?
        if (image.size.width <= self.imageView.image.size.width && image.size.height <= self.imageView.image.size.height) {
            NSLog(@"refusing to use a lower-resolution image.");
            return;
        }
    }

    self.imageView.image = image;
    self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    self.scrollView.contentSize = image.size;
    
    // allow zooming out so that the whole image fits on screen. By default, zoom so that
    // the image fills the screen.
    float minWidthZoom = self.scrollView.frame.size.width / image.size.width;
    float minHeightZoom = self.scrollView.frame.size.height / image.size.height;
    self.scrollView.minimumZoomScale = MIN(minWidthZoom, minHeightZoom);
    self.scrollView.zoomScale = MAX(minWidthZoom, minHeightZoom);
    
    // view insets such that at full zoom out, the image is centered
    float minWidth = self.scrollView.minimumZoomScale * image.size.width;
    float minHeight = self.scrollView.minimumZoomScale * image.size.height;
    float xOffset = (self.scrollView.frame.size.width - minWidth) / 2;
    float yOffset = (self.scrollView.frame.size.height - minHeight) / 2;
    self.scrollView.contentInset = UIEdgeInsetsMake(yOffset, xOffset, yOffset, xOffset);
    
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
    self.scrollView.delegate = nil;
    self.scrollView = nil;
    self.imageView = nil;
    [super dealloc];
}


@end
