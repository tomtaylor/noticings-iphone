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

- (void)addPhotoUploadToQueue:(PhotoUpload *)photoUpload;
- (void)cancelUpload:(PhotoUpload*)upload;
- (void)saveQueuedUploads;
- (void)restoreQueuedUploads;

// operation callbacks
- (void)uploadFailed:(PhotoUpload*)upload;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic, retain) NSOperationQueue *queue;



@end
