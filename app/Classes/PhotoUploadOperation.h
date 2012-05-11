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

@property (nonatomic, retain) PhotoUpload *upload;
@property (nonatomic, assign) UploadQueueManager *manager;

-(id)initWithPhotoUpload:(PhotoUpload*)upload manager:(UploadQueueManager*)manager;

@end
