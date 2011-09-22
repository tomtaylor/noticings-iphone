//
//  CacheManager.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "CacheManager.h"

#import "SynthesizeSingleton.h"
#import "StreamPhoto.h"
#import "ASIHTTPRequest.h"
#import "ObjectiveFlickr.h"

@implementation CacheManager
SYNTHESIZE_SINGLETON_FOR_CLASS(CacheManager);

extern const NSUInteger kMaxDiskCacheSize;

@synthesize cacheDir;
@synthesize imageCache;
@synthesize queue;
@synthesize imageRequests;

- (id)init;
{
    self = [super init];
    if (self) {
        self.imageCache = [NSMutableDictionary dictionary];
        self.imageRequests = [NSMutableDictionary dictionary];
        
        self.queue = [[[NSOperationQueue alloc] init] autorelease];
        self.queue.maxConcurrentOperationCount = 3;
        
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
    // TODO   
}

- (void) clearCache;
{
    // TODO   
}

- (void) flushMemoryCache;
{
    NSLog(@"flushing in-memory cache");
    [self.imageCache removeAllObjects];
}


// return an image for the passed url. Will try the cache first.
- (void)fetchImageForURL:(NSURL*)url andNotify:(NSObject <DeferredImageLoader>*)sender;
{
    NSString *key = [url absoluteString];
    UIImage *image = [self cachedImageForURL:url];
    if (image) {
        // we have a cached version. Send that first. But not till this method is done
        if (sender) {
            // in theory, we should defer this till after the fetchImage call is done. in
            // practice, we want the cached version of the image returned before the 
            // runloop gets a look-in, to avoid flickers of white.
            [sender loadedImage:image cached:YES];
        }
        return;
    }
    
    // for any particular url, we will keep track of which senders are interested, rather
    // than queueing it more than once.
    BOOL alreadyQueued = YES;
    NSMutableArray* listeners = [self.imageRequests objectForKey:key];
    if (!listeners) {
        listeners = [NSMutableArray arrayWithCapacity:1];
        [self.imageRequests setObject:listeners forKey:key];
        alreadyQueued = NO;
    }
    if (sender) {
        // might be nil, because we pre-cache images without nessecarily caring who gets a response
        [listeners addObject:sender];
    }
    
    if (alreadyQueued) {
        return;
    }
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setShouldContinueWhenAppEntersBackground:YES];
    
    [request setCompletionBlock:^{
        UIImage *image = [UIImage imageWithData:[request responseData]];
        NSLog(@"fetched image %@", url);
        [self cacheImage:image forURL:url];
        NSMutableArray* listeners = [self.imageRequests objectForKey:key];
        if (listeners) {
            for (NSObject <DeferredImageLoader>* sender in listeners) {
                [sender loadedImage:image cached:NO];
            }
        }
        [self.imageRequests removeObjectForKey:key];
    }];
    
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"Failed to fetch image %@: %@", url, error);
        [self.imageRequests removeObjectForKey:key];
    }];
    
    [self.queue addOperation:request];
}

- (void)dealloc
{
    self.imageCache = nil;
    self.cacheDir = nil;
    [super dealloc];
}

@end
