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
#import "APIKeys.h"

enum RequestType {
    UploadRequestType,
    LocationRequestType,
    TimestampRequestType
};

@interface UploadQueueManager : NSObject <OFFlickrAPIRequestDelegate> {
	OFFlickrAPIRequest *flickrRequest;
}

+(UploadQueueManager *)sharedUploadQueueManager;

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest imageUploadSentBytes:(NSUInteger)inSentBytes totalBytes:(NSUInteger)inTotalBytes;

- (void)startQueueIfNeeded;
- (void)addPhotoUploadToQueue:(PhotoUpload *)photoUpload;
- (void)pauseQueue;
- (void)fakeUpload;
- (void)cancelUpload:(PhotoUpload*)upload;
- (void)saveQueuedUploads;
- (void)restoreQueuedUploads;

@property (nonatomic, retain) NSMutableArray *photoUploads;
@property (nonatomic) BOOL inProgress;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;



@end
