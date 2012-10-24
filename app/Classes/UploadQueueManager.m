//
//  UploadQueueManager.m
//  Noticings
//
//  Created by Tom Taylor on 18/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "UploadQueueManager.h"
#import "PhotoUpload.h"
#import "GCOAuth.h"
#import "NoticingsAppDelegate.h"
#import "NSString+URI.h"
#import "JSONKit.h"
#import "PhotoUploadOperation.h"

@implementation UploadQueueManager

- (id)init
{
	self = [super init];
	if (self != nil) {
		self.backgroundTask = UIBackgroundTaskInvalid;
        self.uploads = [NSMutableArray array];
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 1;
        [self restoreQueuedUploads];
	}
	return self;
}

- (void)doNext;
{
    // do this a lot.
    [self saveQueuedUploads];

    DLog(@"upload queue is %@", self.uploads);
    if (self.uploads.count == 0) {
        DLog(@"Queue is empty!");
    } else if (self.queue.operationCount > 0) {
        DLog(@"Operation queue is busy!");
    } else {
        // Queue the next unpaused photo
        for (PhotoUpload* upload in self.uploads) {
            if (!upload.paused) {
                DLog(@"adding %@ to operation queue", upload);
                PhotoUploadOperation *op = [[PhotoUploadOperation alloc] initWithPhotoUpload:upload manager:self];
                [self.queue addOperation:op];
                break;
            } else {
                DLog(@"Upload %@ is paused", upload);
            }
        }
    }

    DLog(@"posting badge %u", self.uploads.count);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"queueCount" object:[NSNumber numberWithInt:self.uploads.count]];
}

- (void)addPhotoUploadToQueue:(PhotoUpload *)photoUpload {
    DLog(@"adding upload %@", photoUpload);
    [self.uploads addObject:photoUpload];
    [self doNext];
}

-(void)cancelUpload:(PhotoUpload*)upload;
{
    DLog(@"cancelling %@", upload);
    for (PhotoUploadOperation *op in self.queue.operations) {
        DLog(@"considering %@", op.upload);
        if ([op.upload isEqual:upload]) {
            DLog(@"found that upload in queue");
            [op cancel];
            [op.requestLock signal];
        }
    }
    [self.uploads removeObject:upload];
    [self doNext];
}

- (void)resumeUpload:(PhotoUpload*)upload;
{
    upload.paused = NO;
    upload.progress = 0;
    [self doNext];
}

- (void)startBackgroundTaskIfNeeded {
	UIApplication *app = [UIApplication sharedApplication];
	if (self.backgroundTask == UIBackgroundTaskInvalid) {
		self.backgroundTask = [app beginBackgroundTaskWithExpirationHandler:^{
			[self endBackgroundTask];
		}];
	}
}
						  
- (void)endBackgroundTask {
	UIApplication *app = [UIApplication sharedApplication];
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.backgroundTask != UIBackgroundTaskInvalid) {
			[app endBackgroundTask:self.backgroundTask];
			self.backgroundTask = UIBackgroundTaskInvalid;
		}
	});
}

-(void)uploadSucceeded:(PhotoUpload *)upload;
{
    DLog(@"Upload of %@ succeeded", upload);
    [self.uploads removeObject:upload];
    [self doNext];
}

- (void)uploadFailed:(PhotoUpload*)upload;
{
    DLog(@"Upload of %@ failed", upload);
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {	
        [[[UIAlertView alloc] initWithTitle:@"Upload Error" 
                                     message:[NSString stringWithFormat:@"There was a problem uploading the photo titled '%@'.", upload.title]
                                    delegate:nil
                           cancelButtonTitle:@"OK" 
                           otherButtonTitles:nil] show];
	} else {
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		localNotification.alertBody = [NSString stringWithFormat:@"There was a problem uploading the photo titled '%@'.", upload.title];
		localNotification.hasAction = NO;
		localNotification.soundName = UILocalNotificationDefaultSoundName;
		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
	}

    // operation is complete, having failed. Add a new one to the bottom of the queue, and suspend it.
    upload.paused = YES;
    [self.uploads removeObject:upload];
    [self addPhotoUploadToQueue:upload];
}

- (void)saveQueuedUploads {
    DLog(@"Saving queued uploads");
//	[self pauseQueue];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.uploads];
    DLog(@"archived as %@", data);
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"savedPhotoUploads"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreQueuedUploads {
    DLog(@"Restoring queued uploads");
    [self.queue cancelAllOperations];
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedPhotoUploads"];

    // remove data so that we don't crash forever if the restore fails.
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"savedPhotoUploads"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (!data) return;
    NSArray *savedUploads;
    @try {
        savedUploads = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    @catch (NSException *e) {
        DLog(@"invalid archive");
        return;
    }
    if (![savedUploads isKindOfClass:NSArray.class]) return;
    DLog(@"got %@", savedUploads);

    [self.uploads removeAllObjects];
    [self.uploads addObjectsFromArray:savedUploads];
    // this will re-save the queued photos
    [self doNext];
}

- (void)fakeUpload;
{
    // for debugging
    PhotoUpload *upload = [[PhotoUpload alloc] init];
    upload.title = [NSString stringWithFormat:@"-- fake upload (%@) --", [NSDate date]];
    upload.timestamp = [NSDate date];
    [self addPhotoUploadToQueue:upload];
}

- (void) dealloc {
    [self.queue cancelAllOperations];
}



@end
