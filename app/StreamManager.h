//
//  StreamManager.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObjectiveFlickr.h"

@interface StreamManager : NSObject <OFFlickrAPIRequestDelegate> {
@private
	OFFlickrAPIRequest *flickrRequest;
    NSTimeInterval lastRefresh;
}

+(StreamManager *)sharedStreamManager;

- (void)maybeRefresh;
- (void)refresh;

-(void)loadCachedImageList;
-(void)saveCachedImageList;

- (OFFlickrAPIRequest *)flickrRequest;
- (void) resetFlickrContext;

// interface
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError;

@property (retain) NSMutableArray* photos;
@property (nonatomic) BOOL inProgress;

@end


