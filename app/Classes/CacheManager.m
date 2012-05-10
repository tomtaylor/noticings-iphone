//
//  CacheManager.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import "CacheManager.h"

#import <CommonCrypto/CommonDigest.h>

#import "StreamPhoto.h"
#import "ASIHTTPRequest.h"

@implementation CacheManager

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

- (void) cacheImage:(UIImage *)image fromData:(NSData*)data forURL:(NSURL*)url;
{
    NSString *filename = [self urlToFilename:url];
    
    // store in in-memory cache
    [self.imageCache setObject:image forKey:filename];
    
    // and store on disk
    if (![data writeToFile:filename atomically:TRUE]) {
        NSLog(@"error writing to cache");
    }
}

- (void) clearCacheForURL:(NSURL*)url;
{
    // TODO
}

- (void) clearCache;
{
    [self flushQueue];
    [self.queue cancelAllOperations];
    [self flushMemoryCache];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    for (NSString *file in [fm contentsOfDirectoryAtPath:self.cacheDir error:&error]) {
        NSString *fullFile = [self.cacheDir stringByAppendingPathComponent:file];
        NSLog(@"deleting %@ from cache", fullFile);
        BOOL success = [fm removeItemAtPath:fullFile error:&error];
        if (!success || error) {
            NSLog(@"Fail! %@", error);
        }
    }
}

- (void) flushMemoryCache;
{
    NSLog(@"flushing in-memory cache");
    [self.imageCache removeAllObjects];
}


// return an image for the passed url. Will try the cache first.
- (void)fetchImageForURL:(NSURL*)url andNotify:(NSObject <DeferredImageLoader>*)sender;
{
    // always fetch the image. This doesn't check the cache - you need to do that yourself
    // before calling, because you probably want to handle that case differently.

    BOOL alreadyQueued = YES;

    // rather than always calling flickr, we'll keep track of which requests are already outstanding,
    // and only queue a request once. Everyone else just gets added to the list of "interested
    // parties" and will get called once we have a result.

    @synchronized(self) {
        NSString *key = [url absoluteString];
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
    }
    
    if (alreadyQueued) {
        return;
    }

    NSLog(@"need to fetch %@ for %@", url, sender.class);

    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setShouldContinueWhenAppEntersBackground:YES];

    [request setCompletionBlock:^{
        // this is called on the main thread
        NSLog(@"fetched image %@", url);

        // fetch and store this outside the block to prevent recursive retains of request object.
        NSData *data = [request responseData];
        
        // Do JPEG processing _off_ the main thread.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            UIImage *image = [UIImage imageWithData:data];
            [self cacheImage:image fromData:data forURL:url];
            @synchronized(self) {
                NSString *key = [url absoluteString];
                NSMutableArray* listeners = [self.imageRequests objectForKey:key];
                if (listeners != nil && listeners.count > 0) {
                    for (NSObject <DeferredImageLoader>* sender in listeners) {
                        if (sender != nil) {
                            // notify listeners _on_ the main thread
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [sender loadedImage:image forURL:url cached:NO];
                            }];
                        }
                    }
                }
                [self.imageRequests removeObjectForKey:key];
            }
        });
    }];
    
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"Failed to fetch image %@: %@", url, error);
        @synchronized(self) {
            NSString *key = [url absoluteString];
            [self.imageRequests removeObjectForKey:key];
        }
    }];
    
    [self.queue addOperation:request];
}

- (void)flushQueue;
{
    // call this when we don't care about the contents of the queue any more.
    for (ASIHTTPRequest *op in self.queue.operations) {
        if (!op.inProgress) {
            [op clearDelegatesAndCancel];
        }
    }
    [self.imageRequests removeAllObjects];
}

- (void)dealloc
{
    [self.queue cancelAllOperations];
    self.queue = nil;
    self.imageRequests = nil;
    self.imageCache = nil;
    self.cacheDir = nil;
    [super dealloc];
}

@end
