//
//  UploadQueueManager.h
//  Noticings
//
//  Created by Tom Taylor on 18/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"
#import "ObjectiveFlickr.h"
#import "PhotoUpload.h"
#import "FlickrAPIKeys.h"

enum RequestType {
    UploadRequestType,
    LocationRequestType,
    TimestampRequestType
};

@interface UploadQueueManager : NSObject <OFFlickrAPIRequestDelegate> {
	NSMutableArray *photoUploads;
	OFFlickrAPIRequest *flickrRequest;
	BOOL inProgress;
	UIBackgroundTaskIdentifier backgroundTask;
}

+(UploadQueueManager *)sharedUploadQueueManager;

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest imageUploadSentBytes:(NSUInteger)inSentBytes totalBytes:(NSUInteger)inTotalBytes;

- (void)startQueueIfNeeded;
- (void)addPhotoUploadToQueue:(PhotoUpload *)photoUpload;
- (void)removePhotoUploadAtIndex:(NSInteger)index;
- (void)pauseQueue;
- (void)saveQueuedUploads;
- (void)restoreQueuedUploads;

@property (nonatomic, retain) NSMutableArray *photoUploads;
@property (nonatomic) BOOL inProgress;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;



@end
