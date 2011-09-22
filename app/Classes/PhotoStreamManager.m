//
//  PhotoStreamManager.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "PhotoStreamManager.h"

#import "SynthesizeSingleton.h"
#import "ASIHTTPRequest.h"
#import "APIKeys.h"
#import "CacheManager.h"

@implementation PhotoStreamManager

@synthesize photos;
@synthesize inProgress;
@synthesize lastRefresh;

- (id)init;
{
    self = [super init];
    if (self) {
        self.photos = [NSMutableArray arrayWithCapacity:50];
        self.inProgress = NO;
    }
    
    return self;
}

// refresh, but only if we haven't refreshed recently.
-(void)maybeRefresh;
{
    NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970;
    NSLog(@"it's been %f seconds since refresh", now - lastRefresh);
    if (now - lastRefresh < 60 * 10) {
        // 10 mins
        NSLog(@"not long enough");
        return;
    }
    [self refresh];
}

- (void)refresh;
{
    if (self.inProgress) {
        NSLog(@"Refresh already in progress, refusing to go again.");
        return;
    }
    
    if (![self flickrRequest]) {
        NSLog(@"No authenticated flickr connection - not refreshing.");
        return;
    }
    
    self.inProgress = YES;
    
    NSLog(@"Calling Flickr");
    [self callFlickr];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)callFlickr;
{
    // override in subclass
    NSLog(@"can't use superclass PhotoStreamManager without implementing callFlickr!!");
    assert(FALSE);
}

-(NSString*)extras;
{
    return @"date_upload,date_taken,owner_name,icon_server,geo,path_alias,description,url_m";
}

// TODO - stolen from the uploader. refactor into base class?
- (OFFlickrAPIRequest *)flickrRequest;
{
	if (!flickrRequest) {
        NSString* token = [[NSUserDefaults standardUserDefaults] stringForKey:@"authToken"];
        if (!token) {
            return nil;
        }
        
        NSLog(@"connecting to flickr with token %@", token);
		OFFlickrAPIContext *apiContext = [[OFFlickrAPIContext alloc] initWithAPIKey:FLICKR_API_KEY
                                                                       sharedSecret:FLICKR_API_SECRET];
		[apiContext setAuthToken:[[NSUserDefaults standardUserDefaults] stringForKey:@"authToken"]];
		flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:apiContext];
		flickrRequest.delegate = self;
		flickrRequest.requestTimeoutInterval = 45;
		[apiContext release];
	}
	
	return flickrRequest;
}

- (void)resetFlickrContext;
{
    NSLog(@"binning flickr request");
    // called when the app wakes from sleep - invalidate the flickr request object,
    // in case it is the old, unauthenticated version.
    if (flickrRequest) {
        [flickrRequest cancel]; // stop ongoing HTTP requests
        flickrRequest.delegate = nil;
        [flickrRequest release];
    }
    flickrRequest = nil;
    
    self.inProgress = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}



#pragma mark Flickr delegate methods


- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
    NSLog(@"completed flickr request!");
    
    CacheManager *cacheManager = [CacheManager sharedCacheManager];

    [self.photos removeAllObjects];
    for (NSDictionary *photo in [inResponseDictionary valueForKeyPath:@"photos.photo"]) {
        StreamPhoto *sp = [[StreamPhoto alloc] initWithDictionary:photo];
        [self.photos addObject:sp];
        // pre-cache images
        [cacheManager fetchImageForURL:sp.avatarURL andNotify:nil];
        [cacheManager fetchImageForURL:sp.imageURL andNotify:nil];
        [sp release];
    }
    
    lastRefresh = [[NSDate date] timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970;
    self.inProgress = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    [self fetchComplete];
}

-(void)fetchComplete;
{
    // for subclasses
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
    NSLog(@"failed flickr request! %@", inError);
    self.inProgress = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
	[[[[UIAlertView alloc] initWithTitle:@"Flickr API call failed"
                                 message:@"There was a problem getting your contacts' photos from Flickr."
                                delegate:nil
                       cancelButtonTitle:@"OK"
                       otherButtonTitles:nil]
      autorelease] show];
}




- (void)dealloc
{
    self.photos = nil;
    [flickrRequest release];
    [super dealloc];
}


@end
