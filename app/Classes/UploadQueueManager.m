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

//@synthesize photoUploads = _photoUploads;
@synthesize inProgress = _inProgress;
@synthesize backgroundTask = _backgroundTask;
@synthesize queue = _queue;

- (id)init
{
	self = [super init];
	if (self != nil) {
		self.backgroundTask = UIBackgroundTaskInvalid;
        self.queue = [[[NSOperationQueue alloc] init] autorelease];
        self.queue.maxConcurrentOperationCount = 1;
        [self.queue addObserver:self forKeyPath:@"operations" options:NSKeyValueObservingOptionNew context:nil];
        [self.queue addObserver:self forKeyPath:@"suspended" options:NSKeyValueObservingOptionNew context:nil];
        self.inProgress = FALSE;
        [self restoreQueuedUploads];
	}
	return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    self.inProgress = self.queue.operationCount > 0 && ![self.queue isSuspended];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"queueCount" object:[NSNumber numberWithInt:self.queue.operationCount]];
}

- (void)addPhotoUploadToQueue:(PhotoUpload *)photoUpload {
    PhotoUploadOperation *op = [[PhotoUploadOperation alloc] initWithPhotoUpload:photoUpload manager:self];
    [self.queue addOperation:op];
    [op release];
}

-(void)cancelUpload:(PhotoUpload*)upload;
{
    for (PhotoUploadOperation *op in self.queue.operations) {
        if ([op.upload isEqual:upload]) {
            [op cancel];
        }
    }
}

- (void)startQueueIfNeeded {
    [self.queue setSuspended:NO];
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
        [[[[UIAlertView alloc] initWithTitle:@"Upload Error" 
                                     message:[NSString stringWithFormat:@"There was a problem uploading the photo titled '%@'.", upload.title]
                                    delegate:nil
                           cancelButtonTitle:@"OK" 
                           otherButtonTitles:nil] autorelease] show];
	} else {
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		localNotification.alertBody = [NSString stringWithFormat:@"There was a problem uploading the photo titled '%@'.", upload.title];
		localNotification.hasAction = NO;
		localNotification.soundName = UILocalNotificationDefaultSoundName;
		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
		[localNotification release];
	}

    // operation is complete, having failed. Add a new one to the bottom of the queue, and suspend it.
    PhotoUploadOperation *op = [[PhotoUploadOperation alloc] initWithPhotoUpload:upload manager:self];
    [self.queue addOperation:op];
    [op release];
}

- (void)operationUpdated;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"queueCount" object:[NSNumber numberWithInt:self.queue.operationCount]];
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

- (void)pauseQueue {
    [self.queue setSuspended:YES];
}

- (void)fakeUpload;
{
    // for debugging
    PhotoUpload *upload = [[PhotoUpload alloc] init];
    upload.title = @"fake upload";
    upload.timestamp = [NSDate date];
    upload.inProgress = YES;
    upload.progress = [NSNumber numberWithFloat:0.5];
    self.inProgress = YES;
    [self addPhotoUploadToQueue:upload];
    [upload release];
}

- (void) dealloc {
//    self.photoUploads = nil;
    [self.queue cancelAllOperations];
    self.queue = nil;
	[super dealloc];
}



@end
