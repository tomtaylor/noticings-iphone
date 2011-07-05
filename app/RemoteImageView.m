//
//  RemoteImageView.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
// based on http://www.markj.net/iphone-asynchronous-table-image/

#import "RemoteImageView.h"

@implementation RemoteImageView

-(id)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}


- (void)loadURL:(NSURL*)url;
{
    NSLog(@"Loading image from %@",url);

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
    self.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    [self setNeedsLayout];

    // TODO - cache images based on url in DB or something. Till then, use a very
    // aggressive cache policy. Image URLs don't change.
    NSURLRequest* request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                         timeoutInterval:60.0];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    // TODO - error handling

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
    NSLog(@"Load complete");
    [connection release];
    connection=nil;
    
    // TODO - http://stackoverflow.com/questions/603907/uiimage-resize-then-crop/605385#605385
    self.image = [UIImage imageWithData:data];
    self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    [self setNeedsLayout];

    [data release];
    data=nil;
}

- (void)dealloc
{
    [connection release];
    [data release];
    [super dealloc];
}

@end
