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
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 1;
        [self.queue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
        [self restoreQueuedUploads];
	}
	return self;
}

// queue has changed
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"queueCount" object:[NSNumber numberWithInt:self.queue.operationCount]];
}

- (void)addPhotoUploadToQueue:(PhotoUpload *)photoUpload {
    PhotoUploadOperation *op = [[PhotoUploadOperation alloc] initWithPhotoUpload:photoUpload manager:self];
    [self.queue addOperation:op];
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

- (void)uploadFailed:(PhotoUpload*)upload;
{
    NSLog(@"Upload of %@ failed", upload);
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
    // TODO - need paused uploads for this
//    PhotoUploadOperation *op = [[PhotoUploadOperation alloc] initWithPhotoUpload:upload manager:self];    
//    [self.queue addOperation:op];
//    [op release];
}

- (void)saveQueuedUploads {
//    DLog(@"Saving queued uploads");
//	[self pauseQueue];
//    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.photoUploads];
//    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"savedPhotoUploads"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreQueuedUploads {
//    DLog(@"Restoring queued uploads");
//	[self pauseQueue];
//    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedPhotoUploads"];
//    NSArray *savedUploads = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//    [self.photoUploads removeAllObjects];
//    [self.photoUploads addObjectsFromArray:savedUploads];
}

- (void)fakeUpload;
{
    // for debugging
    PhotoUpload *upload = [[PhotoUpload alloc] init];
    upload.title = @"-- fake upload --";
    upload.timestamp = [NSDate date];
    [self addPhotoUploadToQueue:upload];
}

- (void) dealloc {
//    self.photoUploads = nil;
    [self.queue cancelAllOperations];
}



@end
