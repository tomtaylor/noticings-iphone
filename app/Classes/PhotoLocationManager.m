//
//  PhotoLocationManager.m
//  Noticings
//
//  Created by Tom Insam on 30/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "PhotoLocationManager.h"

#import "SynthesizeSingleton.h"
#import "StreamPhoto.h"
#import "CacheManager.h"
#import "DeferredFlickrCallManager.h"

@implementation PhotoLocationManager
SYNTHESIZE_SINGLETON_FOR_CLASS(PhotoLocationManager);

@synthesize queue, cache, locationRequests;

- (id)init;
{
    self = [super init];
    if (self) {
        self.queue = [[[NSOperationQueue alloc] init] autorelease];
        self.queue.maxConcurrentOperationCount = 1;
        self.locationRequests = [NSMutableDictionary dictionary];
        
        self.cache = [self loadCachedLocations];
    }
    return self;
}

-(NSMutableDictionary*)loadCachedLocations;
{
    NSString* filename = [[CacheManager sharedCacheManager] cachePathForFilename:@"locations.cache"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        return [[[NSMutableDictionary alloc] initWithCapacity:100] autorelease];
    }
    return [[[NSMutableDictionary alloc] initWithContentsOfFile:filename] autorelease];
}

-(void)saveCachedLocations:(NSMutableDictionary*)_cache;
{
    NSString* filename = [[CacheManager sharedCacheManager] cachePathForFilename:@"locations.cache"];
    [_cache writeToFile:filename atomically:YES];
}

-(NSString*)cachedLocationForPhoto:(StreamPhoto*)photo;
{
    NSDictionary *cachedLocation = [self.cache objectForKey:photo.woeid];
    if (cachedLocation) {
        NSString *name = [cachedLocation valueForKeyPath:@"name"];
        return name;
    }
    return nil;
}


-(void)getLocationForPhoto:(StreamPhoto*)photo andTell:(NSObject<LocationDelegate>*)delegate;
{
    // might be called on background thread!
    
    if (!photo.woeid) {
        return;
    }

    // this skips the cache. Always check the cache first, but because every time I do this,
    // I want to do something different if it's cached, we can not bother here.
    
    // rather than always calling flickr, we'll keep track of which location requests are already outstanding,
    // and only queue a request for a location once. Everyone else just gets added to the list of "interested
    // parties" and will get their block called once we have a result.
    BOOL alreadyQueued = YES;

    @synchronized(self) {
        NSMutableArray* listeners = [self.locationRequests objectForKey:photo.woeid];
        if (!listeners) {
            listeners = [NSMutableArray arrayWithCapacity:1];
            [self.locationRequests setObject:listeners forKey:photo.woeid];
            alreadyQueued = NO;
        }
        if (delegate) {
            // might be nil, because we pre-cache images without nessecarily caring who gets a response
            [listeners addObject:delegate];
        }
    }
    
    if (alreadyQueued) {
        // if we're making this request on the default queue, stop here, because
        // the location has already been asked for.
        return;
    }

    NSDictionary *args = [NSDictionary dictionaryWithObject:photo.woeid forKey:@"woe_id"];
    NSString *woeid = photo.woeid;
    
    [[DeferredFlickrCallManager sharedDeferredFlickrCallManager]
    callFlickrMethod:@"flickr.places.getInfo"
    asPost:NO
    withArgs:args
    andThen:^(NSDictionary* rsp) {
        // called on main thread, side-effect of ASHTTPRequest
        
        NSString *name = [rsp valueForKeyPath:@"place.name"];
        if (!name) {
            // store a true value, at least.
            name = @"";
        }
        NSLog(@"Got location name '%@' for woeid %@", name, woeid);
        NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
        NSDictionary *cachedLocation = [NSDictionary dictionaryWithObjectsAndKeys:
            name, @"name",
            [NSString stringWithFormat:@"%d", now], @"date", // for potential cache invalidation later.
            nil];
        [self.cache setObject:cachedLocation forKey:photo.woeid];
        [self saveCachedLocations:self.cache];

        @synchronized(self) {
            NSMutableArray* listeners = [[[self.locationRequests objectForKey:woeid] retain] autorelease];
            [self.locationRequests removeObjectForKey:woeid]; // remove _before_ we dispatch.

            if (listeners != nil && listeners.count > 0) {
                for (NSObject<LocationDelegate>* d in listeners) {
                    // safe, as we're on the main thread
                    [d gotLocation:name forPhoto:photo];
                }
            }
        }

    }
    orFail:^(NSString *code, NSString *err){
        NSLog(@"Failed to get location for woeid %@: %@ %@", photo.woeid, code, err);
        [self.locationRequests removeObjectForKey:photo.woeid];
    }
    ];

}


-(void)dealloc;
{
    [self.queue cancelAllOperations];
    self.queue = nil;
    self.cache = nil;
    self.locationRequests = nil;
    [super dealloc];
}

@end
