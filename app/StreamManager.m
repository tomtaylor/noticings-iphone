//
//  StreamManager.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamManager.h"
#import "StreamPhoto.h"
#import "ASIHTTPRequest.h"

@implementation StreamManager

SYNTHESIZE_SINGLETON_FOR_CLASS(StreamManager);

#define IMAGE_DATA_CACHE @"images.cache"

extern const NSUInteger kMaxDiskCacheSize;

@synthesize photos;
@synthesize inProgress;
@synthesize cacheDir;
@synthesize imageCache;
@synthesize queue;

- (id)init;
{
    self = [super init];
    if (self) {
        self.photos = [NSMutableArray arrayWithCapacity:50];
        self.inProgress = NO;
        self.imageCache = [NSMutableDictionary dictionary];

        self.queue = [[[NSOperationQueue alloc] init] autorelease];
        self.queue.maxConcurrentOperationCount = 2;

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        self.cacheDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"imageCache"];

        // create cache directory if it doesn't exist already.
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.cacheDir]) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:self.cacheDir
                                           withIntermediateDirectories:YES
                                                            attributes:nil
                                                                 error:nil]) {
                NSLog(@"can't create cache folder");
            }
        }

        // It's worth blocking the runloop during app startup while we check the cache to
        // avoid a flash of empty photo list.
        [self loadCachedImageData];
        
    }
    
    return self;
}

-(void)loadCachedImageData;
{
    // TODO - error handling? what if the cache is bad?
    NSString* cache = [self cachePathForFilename:IMAGE_DATA_CACHE];
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

-(void)saveCachedImageData;
{
    NSLog(@"Saving cached image data");
    NSString* cache = [self cachePathForFilename:IMAGE_DATA_CACHE];
    NSMutableData *data = [NSMutableData new];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:self.photos forKey:@"photos"];
    [archiver encodeObject:[NSNumber numberWithDouble:lastRefresh] forKey:@"lastRefresh"];
    [archiver finishEncoding];
    [data writeToFile:cache atomically:YES];
    [archiver release];
    [data release];
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




#pragma mark image cache


-(NSString*) sha256:(NSString *)clear{
    const char *s=[clear cStringUsingEncoding:NSASCIIStringEncoding];
    NSData *keyData=[NSData dataWithBytes:s length:strlen(s)];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH]={0};
    CC_SHA256(keyData.bytes, keyData.length, digest);
    NSData *out=[NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    NSString *hash=[out description];
    hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@">" withString:@""];
    return hash;
}

-(NSString*) cachePathForFilename:(NSString*)filename;
{
    return [self.cacheDir stringByAppendingPathComponent:filename];
}

-(NSString*) urlToFilename:(NSURL*)url;
{
    NSString *hash = [self sha256:[url absoluteString]];
    return [self cachePathForFilename:[hash stringByAppendingPathExtension:@"jpg"]];
}

// try to return an NSImage for the image at this url from a cache.
// There are 2 levels of cache - we cache the raw UIImage in memory for a time,
// but we flush that when the phone needs more memory or when the app gets sent to
// the background. We also store the JPEGs for the images on disk.
//
// TODO - the disk cache needs reaping, based on mtime or something, but we can 
// run for an awfully long time before I need to worry about that.
- (UIImage *) cachedImageForURL:(NSURL*)url;
{
    NSString *filename = [self urlToFilename:url];
    
    // look in in-memory cache first, we're storing the processed image, it's _way_ faster.
    UIImage *inMemory = [self.imageCache objectForKey:filename];
    if (inMemory) {
        return inMemory;
    }
    
    // now look on disk for image. Parsing a JPG takes noticable (barely) time
    // on an iphone 4 so scrolling a list of images off the disk cache will have
    // maybe a frame or 2 of jerk per image.
    // TODO - pre-scale these images to display size? might help.
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        inMemory = [UIImage imageWithContentsOfFile:filename];
        // copy to the in-memory cache
        [self.imageCache setObject:inMemory forKey:filename];
        return inMemory;
    }

    // not in cache
    return nil;
}

- (void) cacheImage:(UIImage *)image forURL:(NSURL*)url;
{
    NSString *filename = [self urlToFilename:url];
    
    // store in in-memory cache
    [self.imageCache setObject:image forKey:filename];
    
    // and store on disk
    NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
    if (![imageData writeToFile:filename atomically:TRUE]) {
        NSLog(@"error writing to cache");
    }
}

- (void) clearCacheForURL:(NSURL*)url;
{
    
}

- (void) clearCache;
{
    
}

- (void) flushMemoryCache;
{
    NSLog(@"flushing in-memory cache");
    [self.imageCache removeAllObjects];
    [self resetFlickrContext];
}


// return an image for the passed url. Will try the cache first.
- (void)fetchImageForURL:(NSURL*)url andNotify:(NSObject <DeferredImageLoader>*)sender;
{
    NSLog(@"fetchImageForURL:%@", url);
    UIImage *image = [self cachedImageForURL:url];
    if (image) {
        // we have a cached version. Send that first. But not till this method is done
        if (sender) {
            // in theory, we should defer this till after the fetchImage call is done. in
            // practice, we want the cached version of the image returned before the 
            // runloop gets a look-in, to avoid flickers of white.
            [sender loadedImage:image cached:YES];
        }
        return YES; // there was a cached version
    }
    
    NSLog(@"need to fetch image %@", url);
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];

    [request setCompletionBlock:^{
        UIImage *image = [UIImage imageWithData:[request responseData]];
        NSLog(@"fetched image %@ for url %@", image, url);
        [self cacheImage:image forURL:url];
        if (sender) {
            [sender loadedImage:image cached:NO];
        }
    }];

    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"Failed to fetch image %@: %@", url, error);
    }];
    [self.queue addOperation:request];
    
    return NO; // had to fetch image
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
    NSLog(@"got %@", inResponseDictionary);

    [self.photos removeAllObjects];
    for (NSDictionary *photo in [inResponseDictionary valueForKeyPath:@"photos.photo"]) {
        StreamPhoto *sp = [[StreamPhoto alloc] initWithDictionary:photo];
        [self.photos addObject:sp];
        // pre-cache images
        [self fetchImageForURL:sp.avatarURL andNotify:nil];
        [self fetchImageForURL:sp.imageURL andNotify:nil];
        [sp release];
    }

    [self saveCachedImageData];
    
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
    self.imageCache = nil;
    self.cacheDir = nil;
    [flickrRequest release];
    [super dealloc];
}

@end
