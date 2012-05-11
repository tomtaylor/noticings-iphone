//
//  UploadQueueManager.h
//  Noticings
//
//  Created by Tom Taylor on 18/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoUpload.h"
#import "APIKeys.h"

@interface UploadQueueManager : NSObject

- (void)startQueueIfNeeded;
- (void)addPhotoUploadToQueue:(PhotoUpload *)photoUpload;
- (void)pauseQueue;
- (void)fakeUpload;
- (void)cancelUpload:(PhotoUpload*)upload;
- (void)saveQueuedUploads;
- (void)restoreQueuedUploads;

// operation callbacks
- (void)operationUpdated;
- (void)uploadFailed:(PhotoUpload*)upload;

//@property (nonatomic, retain) NSMutableArray *photoUploads;
@property (nonatomic) BOOL inProgress;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic, retain) NSOperationQueue *queue;



@end
