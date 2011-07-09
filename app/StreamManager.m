//
//  StreamManager.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamManager.h"
#import "StreamPhoto.h"

@implementation StreamManager

SYNTHESIZE_SINGLETON_FOR_CLASS(StreamManager);

extern const NSUInteger kMaxDiskCacheSize;

@synthesize photos;
@synthesize inProgress;
@synthesize cacheDir;
@synthesize imageCache;

- (id)init;
{
    self = [super init];
    if (self) {
        self.photos = [NSMutableArray arrayWithCapacity:50];
        self.inProgress = NO;

        
        self.imageCache = [NSMutableDictionary dictionary];

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

    
    }
    
    return self;
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

    NSString *extras = @"date_upload,date_taken,owner_name,icon_server,geo,path_alias,description";
    
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"50", @"count",
                          extras, @"extras",
                          @"1", @"include_self",
                          nil];
    
    [[self flickrRequest] callAPIMethodWithGET:@"flickr.photos.getContactsPhotos" arguments:args];
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

-(NSString*) urlToFilename:(NSURL*)url;
{
    NSString *hash = [self sha256:[url absoluteString]];
    NSString *file = [[self.cacheDir stringByAppendingPathComponent:hash] stringByAppendingPathExtension:@"jpg"];
    return file;
}

// try to return an NSImage for the image at this url from a cache.
// There are 2 levels of cache - we cache the raw UIImage in memory for a time,
// but we flush that when the phone needs more memory or when the app gets sent to
// the background. We also store the JPEGs for the images on disk.
//
// TODO - the disk cache needs reaping, based on mtime or something, but we can 
// run for an awfully long time before I need to worry about that.
- (UIImage *) imageForURL:(NSURL*)url;
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
    [flickrRequest release];
    flickrRequest = nil;
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
        [sp release];
    }
    
    self.inProgress = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"newPhotos"
                                                        object:[NSNumber numberWithInt:self.photos.count]];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
    NSLog(@"failed flickr request!");
    self.inProgress = NO;
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
