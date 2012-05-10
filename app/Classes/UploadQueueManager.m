//
//  UploadQueueManager.m
//  Noticings
//
//  Created by Tom Taylor on 18/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "UploadQueueManager.h"
#import "PhotoUpload.h"

@interface UploadQueueManager (Private)

- (void)uploadNextPhoto;
- (void)announceQueueCount;
- (void)nextStageForUploadQueue;
- (void)nextStageForPhotoUpload:(PhotoUpload *)photoUpload;
- (void)uploadPhotoUpload:(PhotoUpload *)photoUpload;
- (void)setLocationForPhotoUpload:(PhotoUpload *)photoUpload;
- (void)setTimestampForPhotoUpload:(PhotoUpload *)photoUpload;
- (void)endBackgroundTask;
- (void)startBackgroundTaskIfNeeded;

@end


@implementation UploadQueueManager

@synthesize photoUploads;
@synthesize inProgress;
@synthesize backgroundTask;

- (id)init
{
	self = [super init];
	if (self != nil) {
		self.photoUploads = [NSMutableArray arrayWithCapacity:3];
		self.inProgress = NO;
		self.backgroundTask = UIBackgroundTaskInvalid;
	}
	return self;
}

- (void)addPhotoUploadToQueue:(PhotoUpload *)photoUpload {
	[self.photoUploads addObject:photoUpload];
	[self announceQueueCount];
}

-(void)cancelUpload:(PhotoUpload*)upload;
{
//    if (upload.inProgress) {
//        [flickrRequest cancel];
//    }
    [self.photoUploads removeObject:upload];
	[self announceQueueCount];
    
    [self nextStageForUploadQueue];
}

- (void)startQueueIfNeeded {
	if ([self.photoUploads count] > 0 && self.inProgress == NO) {
        [self nextStageForUploadQueue];
	}
}

- (void)startBackgroundTaskIfNeeded {
	UIApplication *app = [UIApplication sharedApplication];
	if (backgroundTask == UIBackgroundTaskInvalid) {
		backgroundTask = [app beginBackgroundTaskWithExpirationHandler:^{
			[self endBackgroundTask];
		}];
	}
}
						  
- (void)endBackgroundTask {
	UIApplication *app = [UIApplication sharedApplication];
	dispatch_async(dispatch_get_main_queue(), ^{
		if (backgroundTask != UIBackgroundTaskInvalid) {
			[app endBackgroundTask:backgroundTask];
			backgroundTask = UIBackgroundTaskInvalid;
		}
	});
}

- (void)nextStageForUploadQueue {
	if ([self.photoUploads count] > 0) {
        [self startBackgroundTaskIfNeeded];
        self.inProgress = YES;
		PhotoUpload *photoUpload = [self.photoUploads objectAtIndex:0];
        DLog(@"Starting upload for: %@", photoUpload);
        [self nextStageForPhotoUpload:photoUpload];
	} else {
        self.inProgress = NO;
        [self endBackgroundTask];
    }
}

- (void)nextStageForPhotoUpload:(PhotoUpload *)photoUpload
{
    switch (photoUpload.state) {
        case PhotoUploadStatePendingUpload:
            DLog(@"PhotoUpload (%@) in pending upload state; uploading", photoUpload);
            [self uploadPhotoUpload:photoUpload];
            break;
        
        case PhotoUploadStateUploaded:
            DLog(@"PhotoUpload (%@) in uploaded state; setting location", photoUpload);
            [self setLocationForPhotoUpload:photoUpload];
            break;
            
        case PhotoUploadStateLocationSet:
            DLog(@"PhotoUpload (%@) in location set state; setting timestamp", photoUpload);
            [self setTimestampForPhotoUpload:photoUpload];
            break;
            
        case PhotoUploadStateComplete:
            DLog(@"PhotoUpload (%@) in completed state; finishing", photoUpload);
            photoUpload.inProgress = NO;
            [self.photoUploads removeObject:photoUpload];
            [self announceQueueCount];
            [self nextStageForUploadQueue];
            break;
        
        default:
            break;
    }
}

- (void)uploadPhotoUpload:(PhotoUpload *)photoUpload {
//	OFFlickrAPIRequest *request = [self flickrRequest];
//	
//    photoUpload.inProgress = YES;
//	photoUpload.progress = [NSNumber numberWithFloat:0.0f];
//	
//    NSData *data = [photoUpload imageData];
//    if (!data) {
//        photoUpload.inProgress = NO;
//        self.inProgress = NO;
//        
//        [[[[UIAlertView alloc] initWithTitle:@"Upload Error" 
//                                     message:[NSString stringWithFormat:@"There was a problem uploading the photo titled '%@'. The upload queue has been paused.", photoUpload.title]
//                                    delegate:nil
//                           cancelButtonTitle:@"OK" 
//                           otherButtonTitles:nil] autorelease] show];
//        return;
//    }
//    NSInputStream *imageStream = [NSInputStream inputStreamWithData:data];
//    DLog(@"Input stream: %@", imageStream);
//	
//	NSDictionary *sessionInfo = [NSDictionary dictionaryWithObjectsAndKeys:
//								 photoUpload, @"photoUpload",
//								 [NSNumber numberWithInteger:UploadRequestType], @"requestType", 
//								 nil];
//
//	NSString *uploadedTitleString;
//	
//	if (photoUpload.title == nil || [photoUpload.title isEqualToString:@""]) {
//		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
//		[dateFormatter setDateStyle:NSDateFormatterNoStyle];
//		uploadedTitleString = [dateFormatter stringFromDate:photoUpload.timestamp];
//		[dateFormatter release];
//	} else {
//		uploadedTitleString = photoUpload.title;
//	}
//    
//    NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                      uploadedTitleString, @"title", 
//                                      photoUpload.tags, @"tags",
//                                      nil];
//
//    if (photoUpload.privacy == PhotoUploadPrivacyPrivate) {
//        [arguments setObject:@"0" forKey:@"is_public"];
//    } else if (photoUpload.privacy == PhotoUploadPrivacyFriendsAndFamily) {
//        [arguments setObject:@"1" forKey:@"is_friend"];
//        [arguments setObject:@"1" forKey:@"is_family"];
//        [arguments setObject:@"0" forKey:@"is_public"];
//    } else {
//        [arguments setObject:@"1" forKey:@"is_public"];
//    }
//		
//	[request setSessionInfo:sessionInfo];
//	[request uploadImageStream:imageStream 
//			 suggestedFilename:@"noticing.jpg"
//					  MIMEType:@"image/jpeg"
//					 arguments:arguments
//	 ];
}

- (void)setTimestampForPhotoUpload:(PhotoUpload *)photoUpload {
//    if (photoUpload.timestamp != photoUpload.originalTimestamp) {
//        photoUpload.inProgress = YES;
//        photoUpload.progress = [NSNumber numberWithFloat:0.95f];
//        
//        OFFlickrAPIRequest *request = [self flickrRequest];
//        
//        NSDictionary *sessionInfo = [NSDictionary dictionaryWithObjectsAndKeys:
//                                     photoUpload, @"photoUpload",
//                                     [NSNumber numberWithInteger:TimestampRequestType], @"requestType", 
//                                     nil];
//        
//        [request setSessionInfo:sessionInfo];
//        
//        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
//        [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//        NSString *timestampString = [outputFormatter stringFromDate:photoUpload.timestamp];
//        [outputFormatter release];
//        
//        NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:photoUpload.flickrId, @"photo_id",
//                                   timestampString, @"date_taken",
//                                   nil];
//        
//        [request callAPIMethodWithPOST:@"flickr.photos.setDates" arguments:arguments];
//    } else {
//        photoUpload.state = PhotoUploadStateComplete;
//        [self nextStageForPhotoUpload:photoUpload];
//    }
}

- (void)setLocationForPhotoUpload:(PhotoUpload *)photoUpload {
//    photoUpload.inProgress = YES;
//    photoUpload.progress = [NSNumber numberWithFloat:0.95f];
//
//    // if the coordinate differs from what was set in the asset, then we update the geodata manually
//    if (photoUpload.coordinate.latitude != photoUpload.originalCoordinate.latitude ||
//        photoUpload.coordinate.longitude != photoUpload.originalCoordinate.longitude) {
//        
//        OFFlickrAPIRequest *request = [self flickrRequest];
//        NSDictionary *sessionInfo = [NSDictionary dictionaryWithObjectsAndKeys:
//                                     photoUpload, @"photoUpload",
//                                     [NSNumber numberWithInteger:LocationRequestType], @"requestType", 
//                                     nil];
//        [request setSessionInfo:sessionInfo];
//        
//        if (CLLocationCoordinate2DIsValid(photoUpload.coordinate)) {
//            // set the geodata manually
//            
//            NSNumber *latitudeNumber = [NSNumber numberWithDouble:photoUpload.coordinate.latitude];
//            NSNumber *longitudeNumber = [NSNumber numberWithDouble:photoUpload.coordinate.longitude];
//            
//            DLog(@"Setting latitude to %f, longitude to %f", photoUpload.coordinate.latitude, photoUpload.coordinate.longitude);
//            
//            NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:photoUpload.flickrId, @"photo_id", 
//                                       [latitudeNumber stringValue], @"lat",
//                                       [longitudeNumber stringValue], @"lon",
//                                       nil];
//            
//            [request callAPIMethodWithPOST:@"flickr.photos.geo.setLocation" arguments:arguments];
//            return;
//            
//        } else if (CLLocationCoordinate2DIsValid(photoUpload.originalCoordinate)) {            
//            // remove the geodata manually
//            
//            DLog(@"PhotoUpload did originally have a coordinate, but was removed the map, so removing the geodata manually.");
//            NSDictionary *arguments = [NSDictionary dictionaryWithObject:photoUpload.flickrId forKey:@"photo_id"];
//            [request callAPIMethodWithPOST:@"flickr.photos.geo.removeLocation" arguments:arguments];
//            return;
//        }
//        
//    }
//    
//    // otherwise, just jump to the next stage
//    photoUpload.state = PhotoUploadStateLocationSet;
//    [self nextStageForPhotoUpload:photoUpload];
}

//- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest 
// didCompleteWithResponse:(NSDictionary *)inResponseDictionary
//{
//	PhotoUpload *photoUpload = [inRequest.sessionInfo objectForKey:@"photoUpload"];
//	NSInteger requestType = [[inRequest.sessionInfo objectForKey:@"requestType"] integerValue];
//    
//    switch (requestType) {
//        case UploadRequestType:
//            photoUpload.flickrId = [[inResponseDictionary objectForKey:@"photoid"] textContent];
//            photoUpload.state = PhotoUploadStateUploaded;
//            break;
//            
//        case LocationRequestType:
//            photoUpload.state = PhotoUploadStateLocationSet;
//            break;
//        
//        case TimestampRequestType:
//            photoUpload.state = PhotoUploadStateComplete;
//            photoUpload.progress = [NSNumber numberWithFloat:1.0f];
//            
//        default:
//            break;
//    } 
//    
//    [self nextStageForPhotoUpload:photoUpload];
//}
//
//- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest 
//		didFailWithError:(NSError *)inError
//{
//	PhotoUpload *photoUpload = [inRequest.sessionInfo objectForKey:@"photoUpload"];
//    DLog(@"Photo upload: %@, failed with: %@", photoUpload, inError);
//    photoUpload.inProgress = NO;
//	self.inProgress = NO;
//	
//	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {	
//		[[[[UIAlertView alloc] initWithTitle:@"Upload Error" 
//									 message:[NSString stringWithFormat:@"There was a problem uploading the photo titled '%@'. The upload queue has been paused.", photoUpload.title]
//									delegate:nil
//						   cancelButtonTitle:@"OK" 
//						   otherButtonTitles:nil] autorelease] show];
//	} else {
//		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
//		localNotification.alertBody = [NSString stringWithFormat:@"There was a problem uploading the photo titled '%@'. The upload queue has been paused.", photoUpload.title];
//		localNotification.hasAction = NO;
//		localNotification.soundName = UILocalNotificationDefaultSoundName;
//		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
//		[localNotification release];
//	}
//}
//
//- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest 
//	imageUploadSentBytes:(NSUInteger)inSentBytes 
//			  totalBytes:(NSUInteger)inTotalBytes
//{
//	PhotoUpload *photoUpload = [inRequest.sessionInfo objectForKey:@"photoUpload"];
//	
//	float totalBytesFloat = [[NSNumber numberWithInt:inTotalBytes] floatValue];
//	float sentBytesFloat = [[NSNumber numberWithInt:inSentBytes] floatValue];
//	photoUpload.progress = [NSNumber numberWithFloat:((sentBytesFloat/totalBytesFloat * 0.9))];
//}

- (void)announceQueueCount {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"queueCount" 
														object:[NSNumber numberWithInt:[photoUploads count]]];
}

- (void)saveQueuedUploads {
    DLog(@"Saving queued uploads");
	[self pauseQueue];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.photoUploads];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"savedPhotoUploads"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreQueuedUploads {
    DLog(@"Restoring queued uploads");
	[self pauseQueue];
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedPhotoUploads"];
    NSArray *savedUploads = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [self.photoUploads removeAllObjects];
    [self.photoUploads addObjectsFromArray:savedUploads];
}

- (void)pauseQueue {
//	[flickrRequest cancel];
//	[flickrRequest release];
//	flickrRequest = nil;
	self.inProgress = NO;
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
    self.photoUploads = nil;
//	[flickrRequest cancel];
//	[flickrRequest release];
	[super dealloc];
}



@end
