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

@synthesize queue, cache;

- (id)init;
{
    self = [super init];
    if (self) {
        self.queue = [[[NSOperationQueue alloc] init] autorelease];
        self.queue.maxConcurrentOperationCount = 2;
        
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


-(void)getLocationForPhoto:(StreamPhoto*)photo and:(LocationCallbackBlock)block;
{
    NSDictionary *cachedLocation = [self.cache objectForKey:photo.woeid];
    if (cachedLocation) {
        NSString *name = [cachedLocation valueForKeyPath:@"rsp.place.name"];
        if (block) {
            // this is so that we always call back _after_ the getLocation call, 
            // not "sometimes instantly, sometimes later".
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                block(name);
            }];
        }
        return;
    }
    
    NSDictionary *args = [NSDictionary dictionaryWithObject:photo.woeid forKey:@"woe_id"];
    
    [[DeferredFlickrCallManager sharedDeferredFlickrCallManager]
    callFlickrMethod:@"flickr.places.getInfo"
    withArgs:args
    andThen:^(NSDictionary* rsp) {

        NSString *name = [rsp valueForKeyPath:@"place.name"];
        NSLog(@"Got location name %@ for woeid %@", name, photo.woeid);
        NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
        NSDictionary *cachedLocation = [NSDictionary dictionaryWithObjectsAndKeys:rsp, @"rsp", [NSString stringWithFormat:@"%d", now], @"date", nil];
        [self.cache setObject:cachedLocation forKey:photo.woeid];
        [self saveCachedLocations:self.cache];
        if (block) {
            block(name);
        }

    }
    orFail:nil
    ];

}


-(void)dealloc;
{
    [self.queue cancelAllOperations];
    self.queue = nil;
    self.cache = nil;
    [super dealloc];
}

@end
