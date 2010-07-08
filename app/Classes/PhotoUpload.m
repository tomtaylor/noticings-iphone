//
//  PhotoUpload.m
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoUpload.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation PhotoUpload

@synthesize photo;
@synthesize progress;
@synthesize state;
@synthesize flickrId;
@synthesize title;
@synthesize tags;
@synthesize coordinate;
@synthesize timestamp;

- (id)initWithPhoto:(Photo *)_photo;
{
	self = [super init];
	if (self != nil) {
		self.photo = _photo;
		self.state = PhotoUploadStatePending;
		self.progress = [NSNumber numberWithFloat:0];
		
		if (self.photo.location) {
			self.coordinate = self.photo.location.coordinate;
		} else {
			self.coordinate = kCLLocationCoordinate2DInvalid;
		}
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
	self = [super init];
	if (self != nil) {
		NSNumber *schema = [dictionary objectForKey:@"schema"];
		if (schema == nil)
			return nil;
		
		if ([schema intValue] < 3)
			return nil;
		
		// create photo from asset url
		ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
		
		NSURL *assetURL = [NSURL URLWithString:[dictionary objectForKey:@"assetURL"]];
		
		[library assetForURL:assetURL 
				 resultBlock:^(ALAsset *asset) {
					 Photo *newPhoto = [[Photo alloc] initWithAsset:asset];
					 self.photo = newPhoto;
					 [newPhoto release];
					 //NSLog(@"Restored asset");
					}
				failureBlock:^(NSError *error) {
					NSLog(@"Error opening asset for URL %@: %@", assetURL, error);
				}
		];
		
		[library release];
		
		NSLog(@"Restoring details");
		
		CLLocationDegrees latitude = [[dictionary objectForKey:@"latitude"] floatValue];
		CLLocationDegrees longitude = [[dictionary objectForKey:@"longitude"] floatValue];
		self.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
		
		self.timestamp = [dictionary objectForKey:@"timestamp"];
		self.title = [dictionary objectForKey:@"title"];
		self.tags = [dictionary objectForKey:@"tags"];
		self.flickrId = [dictionary objectForKey:@"flickrId"];
		self.state = [dictionary objectForKey:@"state"];
		self.progress = [NSNumber numberWithFloat:0];
		
		NSLog(@"Restored details");
	}
	return self;
}

- (NSDictionary *)asDictionary {
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:3], @"schema",
			self.state, @"state",
			[[[self.photo.asset defaultRepresentation] url] absoluteString], @"assetURL",
			[NSNumber numberWithFloat:self.coordinate.latitude], @"latitude",
			[NSNumber numberWithFloat:self.coordinate.longitude], @"longitude",
			self.title, @"title",
			self.tags, @"tags",
			self.flickrId, @"flickrId", // this might be nil, but that's OK because it's the last item
			nil];
	
	if (self.timestamp)
		[dict setValue:self.timestamp forKey:@"timestamp"];
	
	return dict;
}

- (void) dealloc
{
	[progress release];
	[photo release];
	[flickrId release];
	[state release];
	[title release];
	[tags release];
	[timestamp release];
	[super dealloc];
}



@end
