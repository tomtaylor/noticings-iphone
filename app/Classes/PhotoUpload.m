//
//  PhotoUpload.m
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoUpload.h"


@implementation PhotoUpload

@synthesize asset;
@synthesize progress;
@synthesize inProgress;
@synthesize state;
@synthesize flickrId;
@synthesize title;
@synthesize tags;
@synthesize location;
@synthesize coordinate;
@synthesize originalCoordinate;
@synthesize timestamp;
@synthesize originalTimestamp;

- (id)initWithAsset:(ALAsset *)_asset
{
	self = [super init];
	if (self != nil) {
		self.asset = _asset;
		self.state = PhotoUploadStatePendingUpload;
        self.inProgress = NO;
		self.progress = [NSNumber numberWithFloat:0.0f];

        self.location = [asset valueForProperty:ALAssetPropertyLocation];
        self.originalTimestamp = [asset valueForProperty:ALAssetPropertyDate];
        self.timestamp = [asset valueForProperty:ALAssetPropertyDate];
        DLog(@"Created PhotoUpload for Asset with location: %@ and timestamp: %@", self.location, self.timestamp);
        		
		if (self.location) {
			self.originalCoordinate = self.location.coordinate;
		} else {
			self.originalCoordinate = kCLLocationCoordinate2DInvalid;
		}
        self.coordinate = originalCoordinate;
	}
	return self;
}

//- (id)initWithDictionary:(NSDictionary *)dictionary {
//	self = [super init];
//	if (self != nil) {
//		NSNumber *schema = [dictionary objectForKey:@"schema"];
//		if (schema == nil)
//			return nil;
//		
//		if ([schema intValue] < 3)
//			return nil;
//		
//		// create photo from asset url
//		ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//		
//		NSURL *assetURL = [NSURL URLWithString:[dictionary objectForKey:@"assetURL"]];
//		
//		[library assetForURL:assetURL 
//				 resultBlock:^(ALAsset *asset) {
//					 Photo *newPhoto = [[Photo alloc] initWithAsset:asset];
//					 self.photo = newPhoto;
//					 [newPhoto release];
//					 //NSLog(@"Restored asset");
//					}
//				failureBlock:^(NSError *error) {
//					NSLog(@"Error opening asset for URL %@: %@", assetURL, error);
//				}
//		];
//		
//		[library release];
//		
//		NSLog(@"Restoring details");
//		
//		CLLocationDegrees latitude = [[dictionary objectForKey:@"latitude"] floatValue];
//		CLLocationDegrees longitude = [[dictionary objectForKey:@"longitude"] floatValue];
//		self.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
//		
//		self.timestamp = [dictionary objectForKey:@"timestamp"];
//		self.title = [dictionary objectForKey:@"title"];
//		self.tags = [dictionary objectForKey:@"tags"];
//		self.flickrId = [dictionary objectForKey:@"flickrId"];
//		self.state = [dictionary objectForKey:@"state"];
//		self.progress = [NSNumber numberWithFloat:0];
//		
//		NSLog(@"Restored details");
//	}
//	return self;
//}
//
//- (NSDictionary *)asDictionary {
//	
//	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:3], @"schema",
//			self.state, @"state",
//			[[[self.photo.asset defaultRepresentation] url] absoluteString], @"assetURL",
//			[NSNumber numberWithFloat:self.coordinate.latitude], @"latitude",
//			[NSNumber numberWithFloat:self.coordinate.longitude], @"longitude",
//			self.title, @"title",
//			self.tags, @"tags",
//			self.flickrId, @"flickrId", // this might be nil, but that's OK because it's the last item
//			nil];
//	
//	if (self.timestamp)
//		[dict setValue:self.timestamp forKey:@"timestamp"];
//	
//	return dict;
//}

- (NSData *)imageData
{
    ALAssetRepresentation *representation = [self.asset defaultRepresentation];
    Byte *buffer = malloc([representation size]);  // will be freed automatically when associated NSData is deallocated
    NSError *err = nil;
    NSUInteger bytes = [representation getBytes:buffer
                                     fromOffset:0LL 
                                         length:[representation size] 
                                          error:&err];
    if (err || bytes == 0) {
        DLog(@"Error getting image data: %@", err);
        return nil;
    }
    
    return [NSData dataWithBytesNoCopy:buffer 
                                length:[representation size]          
                          freeWhenDone:YES];  // YES means free malloc'ed buf that backs this when deallocated
}

- (void) dealloc
{
	[asset release];
	[title release];
	[tags release];
    [progress release];
    [flickrId release];
    [location release];
    [timestamp release];
    [originalTimestamp release];
    [super dealloc];
}



@end
