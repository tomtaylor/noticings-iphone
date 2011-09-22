//
//  StreamManager.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"

#import "ObjectiveFlickr.h"
#import "APIKeys.h"

// protocol for delegates of loadImagefetchImageForURL:andNotify:
@protocol DeferredImageLoader <NSObject>
@required
-(void) loadedImage:(UIImage*)image cached:(BOOL)cached;
@end



@interface StreamManager : NSObject <OFFlickrAPIRequestDelegate> {
@private
	OFFlickrAPIRequest *flickrRequest;
    NSTimeInterval lastRefresh;
}

+(StreamManager *)sharedStreamManager;

- (void)maybeRefresh;
- (void)refresh;

- (OFFlickrAPIRequest *)flickrRequest;
- (UIImage *) cachedImageForURL:(NSURL*)url;
- (void) cacheImage:(UIImage *)image forURL:(NSURL*)url;
- (void) clearCacheForURL:(NSURL*)url;
- (void) clearCache;
- (void) flushMemoryCache;
- (void) resetFlickrContext;

// cache
-(NSString*) cachePathForFilename:(NSString*)filename;
-(NSString*) urlToFilename:(NSURL*)url;
-(void)loadCachedImageData;
-(void)saveCachedImageData;

// deferred image loading
- (void)fetchImageForURL:(NSURL*)url andNotify:(NSObject <DeferredImageLoader>*)sender;

// interface
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError;

@property (retain) NSMutableArray* photos;
@property (nonatomic) BOOL inProgress;

@property (retain) NSString *cacheDir;
@property (retain) NSMutableDictionary *imageCache;

@property (retain) NSOperationQueue *queue;
@end


