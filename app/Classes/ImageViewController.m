//
//  ImageViewController.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import "ImageViewController.h"
#import "NoticingsAppDelegate.h"

@implementation ImageViewController

#define ZOOM_STEP 3

-(id)initWithPhoto:(StreamPhoto*)photo;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.photo = photo;
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

-(void)loadView;
{
    [super loadView];
}

-(void)viewDidLoad;
{
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 20;
    self.scrollView.delegate = self;
    self.scrollView.bouncesZoom = YES;
    self.scrollView.bounces = YES;
    
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.autoresizesSubviews = YES;

    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 1024, 1024 * (480.0f/320))];
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

    [self.view addSubview:self.scrollView];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [[UIApplication sharedApplication] openURL:self.photo.originalImageURL];
    }
}


-(void)scaleAndShowImage:(UIImage*)image;
{
    // snap back out to full zoom before loading, or sometihng odd happens with the extents.
    self.scrollView.zoomScale = 1;
    
    self.imageView.image = image;
    self.imageView.frame = self.view.frame;
    self.scrollView.contentSize = self.imageView.frame.size;
    
    // knock the zoom level in a tiny tiny bit so we get bouncy edges to the scroll view.
    self.scrollView.zoomScale = 1.001;
}


-(void)viewWillAppear:(BOOL)animated;
{
    NSLog(@"%@ will appear", self.class);
    [super viewWillAppear:animated];

    
    // Explicitly _don't_ load the original. Some of those are insane, and you're probably using
    // the wrong app if you care about them.

    __weak ImageViewController* _self = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * data = [[NSData alloc] initWithContentsOfURL:_self.photo.imageURL];
        UIImage * image = [[UIImage alloc] initWithData:data];
        if (image != nil) {
            dispatch_async( dispatch_get_main_queue(), ^{
                [_self scaleAndShowImage:image];
            });
        }

        data = [[NSData alloc] initWithContentsOfURL:_self.photo.bigImageURL];
        image = [[UIImage alloc] initWithData:data];
        if (image != nil) {
            dispatch_async( dispatch_get_main_queue(), ^{
                [_self scaleAndShowImage:image];
            });
        }
    });

    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
}

-(void)viewWillDisappear:(BOOL)animated;
{
    NSLog(@"%@ will disappear", self.class);
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    [super viewWillDisappear:animated];
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
    [self scaleAndShowImage:image];
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
}


@end
