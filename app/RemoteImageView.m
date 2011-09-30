//
//  RemoteImageView.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.

#import "RemoteImageView.h"
#import "CacheManager.h"

@implementation RemoteImageView

@synthesize url;

- (id)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)loadURL:(NSURL*)loadUrl;
{
    self.url = loadUrl;

    self.image = nil;
    self.backgroundColor = [UIColor lightGrayColor];
    [self setNeedsLayout];

    CacheManager *manager = [CacheManager sharedCacheManager];
    [manager fetchImageForURL:loadUrl andNotify:self];
}

- (void)loadedImage:(UIImage *)image cached:(BOOL)cached;
{
    if (self.image) {
        NSLog(@"image already set!");
    } else if (cached) {
        [self setImage:image withAnimation:NO];
    } else {
        [self setImage:image withAnimation:YES];
    }
}

- (void)setImage:(UIImage*)theImage withAnimation:(BOOL)animate;
{
    
    // only animate if there's actually an image.
    if (theImage && animate) {
        self.alpha = 0;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:1.0];
    }
    
    // TODO - http://stackoverflow.com/questions/603907/uiimage-resize-then-crop/605385#605385
    self.image = theImage;
    self.alpha = 1;
    self.backgroundColor = [UIColor whiteColor];
    
    if (theImage && animate) {
        [UIView commitAnimations];
    }
    
    [self setNeedsLayout];
}

- (void)dealloc
{
    self.url = nil;
    [super dealloc];
}

@end
