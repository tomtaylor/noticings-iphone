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
#import "FlickrAPIKeys.h"

@interface StreamManager : NSObject <OFFlickrAPIRequestDelegate> {
@private
	OFFlickrAPIRequest *flickrRequest;
    NSMutableArray *photos;
	BOOL inProgress;
}

+(StreamManager *)sharedStreamManager;

- (void)refresh;

- (OFFlickrAPIRequest *)flickrRequest;

// interface
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError;

@property (retain) NSMutableArray* photos;
@property (nonatomic) BOOL inProgress;

@end
