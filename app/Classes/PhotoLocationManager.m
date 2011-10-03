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
#import "ASIHTTPRequest.h"
#import "APIKeys.h"
#import "OFXMLMapper.h"
#import "CacheManager.h"

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

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.flickr.com/services/rest/?method=flickr.places.getInfo&api_key=%@&woe_id=%@", FLICKR_API_KEY, photo.woeid]];
    
    NSLog(@"getting location %@", url);
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    [request setCompletionBlock:^{
        NSDictionary *responseDictionary = [OFXMLMapper dictionaryMappedFromXMLData:[request responseData]];	
        NSDictionary *rsp = [responseDictionary objectForKey:@"rsp"];
        NSString *stat = [rsp objectForKey:@"stat"];
        
        // this also fails when (responseDictionary, rsp, stat) == nil, so it's a guranteed way of checking the result
        if (![stat isEqualToString:@"ok"]) {
            NSLog(@"flickr error getting %@: %@", url, responseDictionary);
        } else {
            NSString *name = [rsp valueForKeyPath:@"place.name"];
            NSLog(@"Got location name %@ for woeid %@", name, photo.woeid);
            NSDictionary *cachedLocation = [NSDictionary dictionaryWithObjectsAndKeys:rsp, @"rsp", [NSDate date], @"date", nil];
            NSLog(@"caching location %@", cachedLocation);
            [self.cache setObject:cachedLocation forKey:photo.woeid];
            [self saveCachedLocations:self.cache];
            if (block) {
                block(name);
            }
        }
    }];
    
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"Failed to fetch url %@: %@", url, error);
    }];
    
    [self.queue addOperation:request];

}


-(void)dealloc;
{
    [self.queue cancelAllOperations];
    self.queue = nil;
    self.cache = nil;
    [super dealloc];
}

@end
