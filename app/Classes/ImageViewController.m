//
//  ImageViewController.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "ImageViewController.h"

@implementation ImageViewController

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
}

-(void)displayURL:(NSURL*)url;
{
    [[CacheManager sharedCacheManager] fetchImageForURL:url andNotify:self];
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
