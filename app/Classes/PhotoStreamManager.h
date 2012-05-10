//
//  PhotoStreamManager.h
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import <Foundation/Foundation.h>
#import "StreamPhoto.h"
#import "CacheManager.h"
#import "PhotoLocationManager.h"
#import "DeferredFlickrCallManager.h"

// protocol for delegates
@protocol PhotoStreamDelegate <NSObject>
- (void)newPhotos;
@end

@interface PhotoStreamManager : NSObject

- (void)maybeRefresh;
- (void)refresh;

-(void)callFlickrAnd:(FlickrCallback)callback;

-(NSString*)extras;
-(NSString*)cacheFilename;
- (void)resetFlickrContext;

-(void)precache;

-(void)loadCachedImageList;
-(void)saveCachedImageList;

@property (retain) NSMutableArray* rawPhotos;
@property (readonly) NSArray* filteredPhotos;
@property (nonatomic) BOOL inProgress;
@property (nonatomic) NSTimeInterval lastRefresh;

@property (assign) NSObject<PhotoStreamDelegate>* delegate;

@property (readonly) NSString* lastRefreshDisplay;
@end



