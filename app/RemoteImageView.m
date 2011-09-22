//
//  RemoteImageView.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
// based on http://www.markj.net/iphone-asynchronous-table-image/

#import "RemoteImageView.h"

#import "StreamManager.h"

@implementation RemoteImageView

@synthesize url;

-(id)initWithFrame:(CGRect)frame;
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
    StreamManager *manager = [StreamManager sharedStreamManager];

    // TODO - better 'loading' state.
    self.image = nil;
    self.backgroundColor = [UIColor whiteColor];
    [self setNeedsLayout];
    
    [manager fetchImageForURL:loadUrl andNotify:self];
}

-(void)loadedImage:(UIImage *)image cached:(BOOL)cached;
{
    NSLog(@"called loadedImage:%@ cached:%@", image, cached ? @"YES" : @"NO");
    if (cached) {
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
