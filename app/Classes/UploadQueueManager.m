//
//  UploadQueueManager.m
//  Noticings
//
//  Created by Tom Taylor on 18/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "UploadQueueManager.h"

#import "PhotoUpload.h"
#import "Photo.h"

#define UploadRequestType @"upload"
#define LocationRequestType @"location"
#define PermissionsRequestType @"permissions"
#define TimestampRequestType @"timestamp"

@interface UploadQueueManager (Private)

- (void)uploadNextPhoto;
- (void)announceQueueCount;
- (void)uploadPhotoUpload:(PhotoUpload *)photoUpload;
- (void)setLocationForPhotoUpload:(PhotoUpload *)photoUpload;
- (void)setPermissionsForPhotoUpload:(PhotoUpload *)photoUpload;
- (void)setTimestampForPhotoUpload:(PhotoUpload *)photoUpload;
- (void)endBackgroundTask;
- (void)startBackgroundTaskIfNeeded;

@end


@implementation UploadQueueManager

SYNTHESIZE_SINGLETON_FOR_CLASS(UploadQueueManager);

@synthesize photoUploads;
@synthesize inProgress;
@synthesize backgroundTask;

- (id)init
{
	self = [super init];
	if (self != nil) {
		photoUploads = [[NSMutableArray alloc] init];
		self.inProgress = NO;
		self.backgroundTask = UIBackgroundTaskInvalid;
	}
	return self;
}

- (OFFlickrAPIRequest *)flickrRequest
{
	if (!flickrRequest) {
		OFFlickrAPIContext *apiContext = [[OFFlickrAPIContext alloc] initWithAPIKey:FLICKR_API_KEY sharedSecret:FLICKR_API_SECRET];
		[apiContext setAuthToken:[[NSUserDefaults standardUserDefaults] stringForKey:@"authToken"]];
		flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:apiContext];
		flickrRequest.delegate = self;
		flickrRequest.requestTimeoutInterval = 45;
		[apiContext release];
	}
	
	return flickrRequest;
}


- (void)addPhotoUploadToQueue:(PhotoUpload *)photoUpload {
	[self.photoUploads addObject:photoUpload];
	[self announceQueueCount];
}

- (void)removePhotoUploadAtIndex:(NSInteger)index {
	[self.photoUploads removeObjectAtIndex:index];
	[self announceQueueCount];
}

- (void)startQueueIfNeeded {
	if ([self.photoUploads count] > 0 && self.inProgress == NO) {
		//PhotoUpload *photoUpload = [self.photoUploads objectAtIndex:0];
		[self startBackgroundTaskIfNeeded];
		[self uploadNextPhoto];
	} else {
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
			// add cleanup code here
			[app endBackgroundTask:backgroundTask];
			backgroundTask = UIBackgroundTaskInvalid;
		}
	});
}


- (void)uploadNextPhoto {
	if ([self.photoUploads count] > 0) {
		PhotoUpload *photoUpload = [self.photoUploads objectAtIndex:0];
		self.inProgress = YES;
		
		if ([photoUpload.state isEqualToString:PhotoUploadStatePending]) {
			[self uploadPhotoUpload:photoUpload];
		} else if ([photoUpload.state isEqualToString:PhotoUploadStateUploading]) {
			[self uploadPhotoUpload:photoUpload];
		} else if ([photoUpload.state isEqualToString:PhotoUploadStateSettingTimestamp]) {
			[self setTimestampForPhotoUpload:photoUpload];
		} else if ([photoUpload.state isEqualToString:PhotoUploadStateSettingLocation]) {
			[self setLocationForPhotoUpload:photoUpload];
		} else if ([photoUpload.state isEqualToString:PhotoUploadStateSettingPermissions]) {
			[self setPermissionsForPhotoUpload:photoUpload];
		}
	}
}

- (void)uploadPhotoUpload:(PhotoUpload *)photoUpload {
	OFFlickrAPIRequest *request = [self flickrRequest];
	
	photoUpload.state = PhotoUploadStateUploading;
	photoUpload.progress = [NSNumber numberWithFloat:0.0f];
	
	NSInputStream *imageStream = [NSInputStream inputStreamWithData:photoUpload.photo.imageData];
	
	NSDictionary *sessionInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								 photoUpload, @"photoUpload",
								 UploadRequestType, @"requestType", 
								 nil];

	NSString *uploadedTitleString;
	
	if (photoUpload.title == nil || [photoUpload.title isEqualToString:@""]) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setDateStyle:NSDateFormatterNoStyle];
		uploadedTitleString = [dateFormatter stringFromDate:photoUpload.photo.timestamp];
		[dateFormatter release];
	} else {
		uploadedTitleString = photoUpload.title;
	}
		
	[request setSessionInfo:sessionInfo];
	[request uploadImageStream:imageStream 
			 suggestedFilename:@"noticing.jpg"
					  MIMEType:@"image/jpeg"
					 arguments:[NSDictionary dictionaryWithObjectsAndKeys:
								uploadedTitleString, @"title", 
								photoUpload.tags, @"tags", 
								@"1", @"is_public",
								nil]
	 ];
}

- (void)setTimestampForPhotoUpload:(PhotoUpload *)photoUpload {
	photoUpload.state = PhotoUploadStateSettingTimestamp;
	
	OFFlickrAPIRequest *request = [self flickrRequest];
	
	NSDictionary *sessionInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								 photoUpload, @"photoUpload",
								 TimestampRequestType, @"requestType", 
								 nil];
	
	[request setSessionInfo:sessionInfo];
	
	NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
	[outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString *timestampString = [outputFormatter stringFromDate:photoUpload.timestamp];
	[outputFormatter release];
	
	NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:photoUpload.flickrId, @"photo_id",
							   timestampString, @"date_taken",
							   nil];
	
	[request callAPIMethodWithPOST:@"flickr.photos.setDates" arguments:arguments];
																		
}

- (void)setLocationForPhotoUpload:(PhotoUpload *)photoUpload {
	photoUpload.state = PhotoUploadStateSettingLocation;
	
	OFFlickrAPIRequest *request = [self flickrRequest];
	
	NSDictionary *sessionInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								 photoUpload, @"photoUpload",
								 LocationRequestType, @"requestType", 
								 nil];
	
	[request setSessionInfo:sessionInfo];
	
	NSNumber *latitudeNumber = [NSNumber numberWithDouble:photoUpload.coordinate.latitude];
	NSNumber *longitudeNumber = [NSNumber numberWithDouble:photoUpload.coordinate.longitude];
	
	NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:photoUpload.flickrId, @"photo_id", 
							   [latitudeNumber stringValue], @"lat",
							   [longitudeNumber stringValue], @"lon",
							   nil];
	
	[request callAPIMethodWithPOST:@"flickr.photos.geo.setLocation" arguments:arguments];

}

- (void)setPermissionsForPhotoUpload:(PhotoUpload *)photoUpload {
	photoUpload.state = PhotoUploadStateSettingPermissions;
	
	OFFlickrAPIRequest *request = [self flickrRequest];
	
	NSDictionary *sessionInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								 photoUpload, @"photoUpload",
								 PermissionsRequestType, @"requestType", 
								 nil];
	
	[request setSessionInfo:sessionInfo];
	
	NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:photoUpload.flickrId, @"photo_id",
							   @"1", @"is_public",
							   @"1", @"is_friend",
							   @"1", @"is_family",
							   @"1", @"is_contact",
							   nil];
	
	[request callAPIMethodWithPOST:@"flickr.photos.geo.setPerms" arguments:arguments];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest 
 didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
	PhotoUpload *photoUpload = [inRequest.sessionInfo objectForKey:@"photoUpload"];
	NSString *requestType = [inRequest.sessionInfo objectForKey:@"requestType"];
	
	if ([requestType isEqualToString:UploadRequestType]) {
		photoUpload.flickrId = [[inResponseDictionary objectForKey:@"photoid"] textContent];
		
		if (!photoUpload.photo.timestamp && photoUpload.photo.timestamp != photoUpload.timestamp) {
			[self setTimestampForPhotoUpload:photoUpload];
		} else {
			[self setLocationForPhotoUpload:photoUpload];
		}
		
	} else if ([requestType isEqualToString:TimestampRequestType]) {
		[self setLocationForPhotoUpload:photoUpload];
	} else if ([requestType isEqualToString:LocationRequestType]) {
		[self setPermissionsForPhotoUpload:photoUpload];
	} else {
		[photoUploads removeObjectAtIndex:0];
		[self announceQueueCount];
		
		if ([self.photoUploads count] > 0) {
			[self uploadNextPhoto];
		} else {
			self.inProgress = NO;
			[self endBackgroundTask];
		}
	}
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest 
		didFailWithError:(NSError *)inError
{
	PhotoUpload *photoUpload = [inRequest.sessionInfo objectForKey:@"photoUpload"];
	photoUpload.progress = [NSNumber numberWithFloat:0.0f];
	
	self.inProgress = NO;
	
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {	
		[[[[UIAlertView alloc] initWithTitle:@"Upload Error" 
									 message:[NSString stringWithFormat:@"There was a problem uploading the photo titled '%@'. The upload queue has been paused.", photoUpload.title]
									delegate:nil
						   cancelButtonTitle:@"OK" 
						   otherButtonTitles:nil] autorelease] show];
	} else {
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		localNotification.alertBody = [NSString stringWithFormat:@"There was a problem uploading the photo titled '%@'. The upload queue has been paused.", photoUpload.title];
		localNotification.hasAction = NO;
		localNotification.soundName = UILocalNotificationDefaultSoundName;
		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
		[localNotification release];
	}
	
	NSLog(@"Error in state: %@, %@", photoUpload.state, inError);
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest 
	imageUploadSentBytes:(NSUInteger)inSentBytes 
			  totalBytes:(NSUInteger)inTotalBytes
{
	PhotoUpload *photoUpload = [inRequest.sessionInfo objectForKey:@"photoUpload"];
	
	float totalBytesFloat = [[NSNumber numberWithInt:inTotalBytes] floatValue];
	float sentBytesFloat = [[NSNumber numberWithInt:inSentBytes] floatValue];
	photoUpload.progress = [NSNumber numberWithFloat:(sentBytesFloat/totalBytesFloat)];
}

- (void)announceQueueCount {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"queueCount" 
														object:[NSNumber numberWithInt:[photoUploads count]]];
}

- (void)saveQueuedUploads {
	[self pauseQueue];
	
	NSLog(@"Saving queued uploads");
	
	NSMutableArray *savedUploads = [[NSMutableArray alloc] initWithCapacity:[self.photoUploads count]];

	for (int i = 0; i < [self.photoUploads count]; i++) {
		PhotoUpload *photoUpload = [self.photoUploads objectAtIndex:i];
		NSDictionary *dict = [photoUpload asDictionary];
		NSLog(@"Saving dictionary: %@", dict);
		[savedUploads addObject:dict];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:savedUploads forKey:@"savedUploads"];
	[savedUploads release];
}

- (void)restoreQueuedUploads {
	[self pauseQueue];
	
	NSArray *savedUploads = [[NSUserDefaults standardUserDefaults] arrayForKey:@"savedUploads"];
	
	if (savedUploads != nil) {
		for (int i=0; i < [savedUploads count]; i++) {
			NSDictionary *dict = [savedUploads objectAtIndex:i];
			NSLog(@"Restoring from dictionary: %@", dict);
			
			PhotoUpload *photoUpload = [[PhotoUpload alloc] initWithDictionary:dict];
			
			if (photoUpload != nil) {
				[self.photoUploads addObject:photoUpload];
			}
			
			[photoUpload release];
		}
	}
}

- (void)pauseQueue {
	[flickrRequest cancel];
	[flickrRequest release];
	flickrRequest = nil;
	self.inProgress = NO;
}

- (void) dealloc {
	[photoUploads release];
	[flickrRequest cancel];
	[flickrRequest release];
	[super dealloc];
}



@end
