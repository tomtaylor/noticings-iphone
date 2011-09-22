//
//  StreamManager.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SynthesizeSingleton.h"
#import "StreamManager.h"
#import "StreamPhoto.h"
#import "ASIHTTPRequest.h"
#import "APIKeys.h"
#import "CacheManager.h"

@implementation StreamManager
SYNTHESIZE_SINGLETON_FOR_CLASS(StreamManager);

#define IMAGE_DATA_CACHE @"images.cache"

@synthesize photos;
@synthesize inProgress;

- (id)init;
{
    self = [super init];
    if (self) {
        self.photos = [NSMutableArray arrayWithCapacity:50];
        self.inProgress = NO;

        // It's worth blocking the runloop during app startup while we check the cache to
        // avoid a flash of empty photo list.
        [self loadCachedImageList];
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
    
    NSLog(@"Refreshing from Flickr..");
    
    self.inProgress = YES;
    
    NSString *extras = @"date_upload,date_taken,owner_name,icon_server,geo,path_alias,description,url_m";
    
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"50", @"count",
                          extras, @"extras",
                          @"1", @"include_self",
                          nil];
    
    [[self flickrRequest] callAPIMethodWithGET:@"flickr.photos.getContactsPhotos" arguments:args];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}


// load the cached list of images fetched from flickr
-(void)loadCachedImageList;
{
    // TODO - error handling? what if the cache is bad?
    NSString* cache = [[CacheManager sharedCacheManager] cachePathForFilename:IMAGE_DATA_CACHE];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cache]) {
        return; // no cache
    }
    NSLog(@"Loading cached image data");
    NSData *data = [[NSData alloc] initWithContentsOfFile:cache];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSArray *archived = [[unarchiver decodeObjectForKey:@"photos"] retain];
    NSNumber *archivedLastRefresh = [[unarchiver decodeObjectForKey:@"lastRefresh"] retain];
    [unarchiver release];
    [data release];
    
    // don't replace self.photos, alter, so we fire the watchers.
    [self.photos removeAllObjects];
    for (StreamPhoto *photo in archived) {
        [self.photos addObject:photo];
    }
    [archived release];
    
    lastRefresh = [archivedLastRefresh doubleValue];
    [archivedLastRefresh release];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"newPhotos"
                                                        object:[NSNumber numberWithInt:self.photos.count]];
}

// save the cached list of images fetched from flickr
-(void)saveCachedImageList;
{
    NSLog(@"Saving cached image data");
    NSString* cache = [[CacheManager sharedCacheManager] cachePathForFilename:IMAGE_DATA_CACHE];
    NSMutableData *data = [NSMutableData new];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:self.photos forKey:@"photos"];
    [archiver encodeObject:[NSNumber numberWithDouble:lastRefresh] forKey:@"lastRefresh"];
    [archiver finishEncoding];
    [data writeToFile:cache atomically:YES];
    [archiver release];
    [data release];
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

    // this tells the view controller that we're done with whatever we were doing - it hides the 'loading' message
	[[NSNotificationCenter defaultCenter] postNotificationName:@"newPhotos"
                                                        object:[NSNumber numberWithInt:self.photos.count]];

}



#pragma mark Flickr delegate methods


- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
    NSLog(@"completed flickr request!");
    //NSLog(@"got %@", inResponseDictionary);
    
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

    [self saveCachedImageList];
    
    self.inProgress = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"newPhotos"
                                                        object:[NSNumber numberWithInt:self.photos.count]];


    NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970;
    lastRefresh = now;
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
