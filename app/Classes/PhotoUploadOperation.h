//
//  PhotoUploadOperation.h
//  Noticings
//
//  Created by Tom Insam on 10/05/2012.
//  Copyright (c) 2012 Lanyrd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoUpload.h"
#import "UploadQueueManager.h"

@interface PhotoUploadOperation : NSOperation

@property (nonatomic, strong) PhotoUpload *upload;
@property (nonatomic, weak) UploadQueueManager *manager;

// URL request stuff
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSCondition *requestLock;
@property (nonatomic) BOOL requestFinished;
@property (nonatomic) BOOL requestFailed;

-(id)initWithPhotoUpload:(PhotoUpload*)upload manager:(UploadQueueManager*)manager;

@end
