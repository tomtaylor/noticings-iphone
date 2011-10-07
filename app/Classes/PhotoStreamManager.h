//
//  PhotoStreamManager.h
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObjectiveFlickr.h"
#import "StreamPhoto.h"

@interface PhotoStreamManager : NSObject <OFFlickrAPIRequestDelegate> {
@private
	OFFlickrAPIRequest *flickrRequest;
}

- (void)maybeRefresh;
- (void)refresh;

-(void)callFlickr;
-(NSString*)extras;
-(NSString*)cacheFilename;
- (void)resetFlickrContext;
- (OFFlickrAPIRequest *)flickrRequest;

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError;

-(void)precache;

-(void)loadCachedImageList;
-(void)saveCachedImageList;

@property (retain) NSMutableArray* photos;
@property (nonatomic) BOOL inProgress;
@property (nonatomic) NSTimeInterval lastRefresh;

@property (assign) id delegate;

@property (readonly) NSString* lastRefreshDisplay;
@end


