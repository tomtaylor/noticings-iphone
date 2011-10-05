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
@synthesize delegate;

- (id)init;
{
    self = [super init];
    if (self) {
        self.photos = [NSMutableArray arrayWithCapacity:50];
        self.inProgress = NO;

        // It's worth blocking the runloop during app startup while we check
        // the cache, to avoid a flash of empty photo list.
        [self loadCachedImageList];
    }
    
    return self;
}

// refresh, but only if we haven't refreshed recently.
-(void)maybeRefresh;
{
    NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970;
    NSLog(@"it's been %f seconds since refresh", now - self.lastRefresh);
    if (now - self.lastRefresh < 60 * 10) {
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
    return @"date_upload,date_taken,owner_name,icon_server,geo,path_alias,description,url_m,url_o,tags,media";
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

-(NSString*)cacheFilename;
{
    return @""; 
}

// load the cached list of images fetched from flickr
-(void)loadCachedImageList;
{
    if ([self cacheFilename].length == 0) {
        return;
    }

    // TODO - error handling? what if the cache is bad?
    NSString* cache = [[CacheManager sharedCacheManager] cachePathForFilename:[self cacheFilename]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cache]) {
        return; // no cache
    }
    NSLog(@"Loading cached image data from %@", cache);
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
    
    self.lastRefresh = [archivedLastRefresh doubleValue];
    [archivedLastRefresh release];
}

// save the cached list of images fetched from flickr
-(void)saveCachedImageList;
{
    if ([self cacheFilename].length == 0) {
        return;
    }

    NSString* cache = [[CacheManager sharedCacheManager] cachePathForFilename:[self cacheFilename]];
    NSLog(@"Saving cached image data to %@", cache);
    NSMutableData *data = [NSMutableData new];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:self.photos forKey:@"photos"];
    [archiver encodeObject:[NSNumber numberWithDouble:self.lastRefresh] forKey:@"lastRefresh"];
    [archiver finishEncoding];
    [data writeToFile:cache atomically:YES];
    [archiver release];
    [data release];
}




#pragma mark Flickr delegate methods


- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
    NSLog(@"completed flickr request");
    
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
    
    self.lastRefresh = [[NSDate date] timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970;
    self.inProgress = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSLog(@"loaded %d photos", [self.photos count]);

    if (self.delegate) {
        [self.delegate performSelector:@selector(newPhotos)];
    }

    [self saveCachedImageList];
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
    NSLog(@"deallocing %@", self.class);
    [flickrRequest cancel];
    flickrRequest.delegate = nil;
    [flickrRequest release];
    self.delegate = nil;
    self.photos = nil;
    [super dealloc];
}


@end
