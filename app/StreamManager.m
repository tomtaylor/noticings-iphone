//
//  StreamManager.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamManager.h"
#import "SynthesizeSingleton.h"
#import "CacheManager.h"

@implementation StreamManager
SYNTHESIZE_SINGLETON_FOR_CLASS(StreamManager);

-(id)init;
{
    self = [super init];
    if (self) {
        // It's worth blocking the runloop during app startup while we check
        // the cache, to avoid a flash of empty photo list.
        [self loadCachedImageList];
    }
    return self;
}

-(void) callFlickr;
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"50", @"count",
                          [self extras], @"extras",
                          @"1", @"include_self",
                          nil];
    [[self flickrRequest] callAPIMethodWithGET:@"flickr.photos.getContactsPhotos" arguments:args];
}


-(void)fetchComplete;
{
    [self saveCachedImageList];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"newPhotos" object:[NSNumber numberWithInt:self.photos.count]];
}


// load the cached list of images fetched from flickr
-(void)loadCachedImageList;
{
    // TODO - error handling? what if the cache is bad?
    NSString* cache = [[CacheManager sharedCacheManager] cachePathForFilename:@"images.cache"];
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
    
    self.lastRefresh = [archivedLastRefresh doubleValue];
    [archivedLastRefresh release];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"newPhotos" object:[NSNumber numberWithInt:self.photos.count]];
}

// save the cached list of images fetched from flickr
-(void)saveCachedImageList;
{
    NSLog(@"Saving cached image data");
    NSString* cache = [[CacheManager sharedCacheManager] cachePathForFilename:@"images.cache"];
    NSMutableData *data = [NSMutableData new];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:self.photos forKey:@"photos"];
    [archiver encodeObject:[NSNumber numberWithDouble:self.lastRefresh] forKey:@"lastRefresh"];
    [archiver finishEncoding];
    [data writeToFile:cache atomically:YES];
    [archiver release];
    [data release];
}


@end
