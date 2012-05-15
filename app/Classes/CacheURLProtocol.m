//
//  CacheURLProtocol.m
//  Noticings
//
//  Created by Tom Insam on 14/05/2012.
//  Copyright (c) 2012 Lanyrd. All rights reserved.
//

#import "CacheURLProtocol.h"
#import "CacheManager.h"
#import "NoticingsAppDelegate.h"

@implementation CacheURLProtocol

@synthesize request = request_;
@synthesize connection = connection_;
@synthesize data = data_;
@synthesize response = response_;

+ (BOOL)canInitWithRequest:(NSURLRequest *)request;
{
    if ([request.URL.scheme isEqualToString:@"cache"]) {
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request;
{
    return request;
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id <NSURLProtocolClient>)client;
{
    self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    if (self) {
        self.request = request;
        self.connection = nil;
    }
    return self;
}

-(void)respond:(NSData*)data;
{
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:nil expectedContentLength:-1 textEncodingName:nil];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];  // We cache ourselves.
    [response release];
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
}


- (void)startLoading;
{
//    DLog(@"startLoading %@", self.request.URL);
    
    // fix scheme up from cache to http;.
    NSMutableURLRequest *myRequest = [[self.request mutableCopy] autorelease];
    myRequest.URL = [NSURL URLWithString:[myRequest.URL.absoluteString stringByReplacingCharactersInRange:NSMakeRange(0, 5) withString:@"http"]];
    
    CacheManager *cache = [NoticingsAppDelegate delegate].cacheManager;
    NSString *filename = [cache urlToFilename:self.request.URL];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        NSData *data = [NSData dataWithContentsOfFile:filename];
        [self respond:data];
        return;
    }

    DLog(@"..fetching %@ from internet", myRequest.URL);
    self.connection = [NSURLConnection connectionWithRequest:myRequest delegate:self];

}

-(void)dealloc;
{
    [self stopLoading];
    self.data = nil;
    self.response = nil;
    self.connection = nil;
    [super dealloc];
}

- (void)stopLoading;
{
    if (self.connection) {
        [self.connection cancel];
    }
}

// NSURLConnection delegates (generally we pass these on to our client)

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newData
{
    [[self client] URLProtocol:self didLoadData:newData];
    
    if (self.data) {
        [self.data appendData:newData];
    } else {
        self.data = [NSMutableData dataWithData:newData];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    DLog(@"%@ failed to fetch %@: %@", self, self.request.URL, error);
    [[self client] URLProtocol:self didFailWithError:error];
    self.connection = nil;
    self.response = nil;
    self.data = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];  // We cache ourselves.
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[self client] URLProtocolDidFinishLoading:self];
    
    if ([self.response isKindOfClass:NSHTTPURLResponse.class]) {
        NSHTTPURLResponse *resp = (NSHTTPURLResponse*)self.response;
        if (resp.statusCode == 200) {
            DLog(@"Sensible HTTP response.");
            CacheManager *cache = [NoticingsAppDelegate delegate].cacheManager;
            NSString *filename = [cache urlToFilename:self.request.URL];
            [self.data writeToFile:filename atomically:YES];
            [self respond:self.data];
        } else {
            DLog(@"Non-200 status code from HTTP response, not caching.");
            [self respond:self.data];
        }
    } else {
        DLog(@"Not caching non-HTTP response.");
    }
    
    self.connection = nil;
    self.response = nil;
    self.data = nil;
}


@end
