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
    UIImage *image = [manager imageForURL:loadUrl];
    if (image) {
        [self setImage:image withAnimation:NO];
        return;
    }
        
    NSLog(@"Loading image from %@",loadUrl);
    self.url = loadUrl;

    // if we've been told to stop and load something else, make sure the old thing is dead.
    if (connection!=nil) {
        [connection cancel];
        [connection release];
    }

    if (data!=nil) {
        [data release];
        data = nil;
    }
    
    // TODO - better 'loading' state.
    self.image = nil;
    self.backgroundColor = [UIColor whiteColor];
    [self setNeedsLayout];

    // TODO - cache images based on url in DB or something. Till then, use a very
    // aggressive cache policy. Image URLs don't change.
    NSURLRequest* request = [NSURLRequest requestWithURL:loadUrl
                                             cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                         timeoutInterval:60.0];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    // TODO - error handling

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData
{
    if (data == nil) {
        data = [[NSMutableData alloc] initWithCapacity:2048];
    }
    [data appendData:incrementalData];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection
{
    [connection release];
    connection=nil;
    
    StreamManager *manager = [StreamManager sharedStreamManager];
    
    UIImage *theImage = [UIImage imageWithData:data];
    if (theImage) {
        [manager cacheImage:theImage forURL:self.url];
        [self setImage:theImage withAnimation:YES];
    } else {
        // TODO error handling. Failed to parse image?
        NSLog(@"Failed to parse an image from data %@", data);
    }

    [data release];
    data=nil;

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
    [connection release];
    [data release];
    [super dealloc];
}

@end
