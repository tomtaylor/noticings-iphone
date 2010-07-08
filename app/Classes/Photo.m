//
//  Photo.m
//  Noticings
//
//  Created by Tom Taylor on 06/08/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Photo.h"

@interface Photo (Private)

@end


@implementation Photo

@synthesize asset;
@synthesize timestamp;
@synthesize thumbnailImage;
@synthesize location;
@synthesize imageData;

- (id) initWithAsset:(ALAsset *)anAsset
{
	self = [super init];
	if (self != nil) {
		self.asset = anAsset;
		noLocation = NO;
	}
	return self;
}

- (NSDate *)timestamp {
	if (timestamp == nil)
		timestamp = [[asset valueForProperty:ALAssetPropertyDate] retain];
	
	return timestamp;
}

- (UIImage *)thumbnailImage {
	if (thumbnail == nil)
		thumbnail = [[UIImage imageWithCGImage:[asset thumbnail]] retain];
	
	return thumbnail;
}

- (CLLocation *)location {
	if (location == nil || noLocation) {
		NSDictionary *metadata = [[asset defaultRepresentation] metadata];
		NSDictionary *gpsMetdata = [metadata objectForKey:@"{GPS}"];
		
		if (gpsMetdata) {
			CLLocationDegrees latitude = [[gpsMetdata objectForKey:@"Latitude"] doubleValue];
			//NSLog(@"GPS: %@", gpsMetdata);
			CLLocationDegrees longitude = [[gpsMetdata objectForKey:@"Longitude"] doubleValue];
			NSString *latitudeRef = [gpsMetdata objectForKey:@"LatitudeRef"];
			NSString *longitudeRef = [gpsMetdata objectForKey:@"LongitudeRef"];
			
			if ([latitudeRef isEqualToString:@"S"])
				latitude = -latitude;
			
			if ([longitudeRef isEqualToString:@"W"])
				longitude = -longitude;
			
			location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];			
		} else {
			noLocation = YES;
		}		
	}
	
	return location;
}

- (NSData *)imageData {
	ALAssetRepresentation *assetRep = [self.asset defaultRepresentation];
	
	NSUInteger size = [assetRep size];
	uint8_t *buff = malloc(size);
	
	NSError *err = nil;
	NSUInteger gotByteCount = [assetRep getBytes:buff fromOffset:0 length:size error:&err];
	
	if (gotByteCount) {
		if (err) {
			NSLog(@"!!! Error reading asset: %@", [err localizedDescription]);
			[err release];
			free(buff);
			return nil;
		}
	}
	
	return [NSData dataWithBytesNoCopy:buff length:size freeWhenDone:YES];
}

- (void)freeCache {
	[thumbnail release];
	thumbnail = nil;
	
	[timestamp release];
	timestamp = nil;
	
	[location release];
	location = nil;
	
	noLocation = NO;
}
	

- (void) dealloc {
	[asset release];
	[timestamp release];
	[thumbnail release];
	[location release];
	[super dealloc];
}

@end
