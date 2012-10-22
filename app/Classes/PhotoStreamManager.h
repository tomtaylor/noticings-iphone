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

@property (strong) NSMutableArray* rawPhotos;
@property (weak, readonly) NSArray* filteredPhotos;
@property (nonatomic) BOOL inProgress;
@property (nonatomic) NSTimeInterval lastRefresh;
@property (weak) NSObject<PhotoStreamDelegate>* delegate;
@property (weak, readonly) NSString* lastRefreshDisplay;
@end



