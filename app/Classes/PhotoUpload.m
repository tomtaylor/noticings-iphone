//
//  PhotoUpload.m
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoUpload.h"

@interface PhotoUpload (Private)
+ (ALAsset *)assetForURL:(NSURL *)url;
@end

@implementation PhotoUpload

enum {
    ASSETURL_PENDINGREADS = 1,
    ASSETURL_ALLFINISHED = 0
};

@synthesize asset;
@synthesize progress;
@synthesize inProgress;
@synthesize privacy;
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
        self.inProgress = FALSE;
		self.progress = @0.0f;

        self.privacy = PhotoUploadPrivacyPublic;
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

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:4 forKey:@"version"];
    [coder encodeObject:self.asset.defaultRepresentation.url forKey:@"assetUrl"];
    [coder encodeConditionalObject:self.title forKey:@"title"];
    [coder encodeConditionalObject:self.tags forKey:@"tags"];
    [coder encodeInt:self.privacy forKey:@"privacy"];
    [coder encodeConditionalObject:self.flickrId forKey:@"flickrId"];
    [coder encodeConditionalObject:self.location forKey:@"location"];
    [coder encodeConditionalObject:self.timestamp forKey:@"timestamp"];
    [coder encodeConditionalObject:self.originalTimestamp forKey:@"originalTimestamp"];
    
    [coder encodeDouble:coordinate.latitude forKey:@"coordinate.latitude"];
    [coder encodeDouble:coordinate.longitude forKey:@"coordinate.longitude"];
    
    [coder encodeDouble:originalCoordinate.latitude forKey:@"originalCoordinate.latitude"];
    [coder encodeDouble:originalCoordinate.longitude forKey:@"originalCoordinate.longitude"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
	if (self != nil) {
        int version = [decoder decodeIntForKey:@"version"];
        if (version < 4) {
            return nil;
        }
        
        // create photo from asset url
        NSURL *assetURL = [decoder decodeObjectForKey:@"assetUrl"];
        self.asset = [PhotoUpload assetForURL:assetURL];
        
        self.title = [decoder decodeObjectForKey:@"title"];
        self.tags = [decoder decodeObjectForKey:@"tags"];
        self.privacy = [decoder decodeIntForKey:@"privacy"];
        self.flickrId = [decoder decodeObjectForKey:@"flickrId"];
        self.location = [decoder decodeObjectForKey:@"location"];
        self.timestamp = [decoder decodeObjectForKey:@"timestamp"];
        self.originalTimestamp = [decoder decodeObjectForKey:@"originalTimestamp"];
        
        CLLocationCoordinate2D aCoordinate;
        aCoordinate.latitude = [decoder decodeDoubleForKey:@"coordinate.latitude"];
        aCoordinate.longitude = [decoder decodeDoubleForKey:@"coordinate.longitude"];
        coordinate = aCoordinate;
        
        CLLocationCoordinate2D anOriginalCoordinate;
        anOriginalCoordinate.latitude = [decoder decodeDoubleForKey:@"originalCoordinate.latitude"];
        anOriginalCoordinate.longitude = [decoder decodeDoubleForKey:@"originalCoordinate.longitude"];
        originalCoordinate = anOriginalCoordinate;
                
        self.inProgress = NO;
		self.progress = @0.0f;
    }
    return self;
}

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

+ (ALAsset *)assetForURL:(NSURL *)url {
    __block ALAsset *result = nil;
    __block NSError *assetError = nil;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    
    [assetsLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
        result = [asset retain];
        dispatch_semaphore_signal(sema);
    } failureBlock:^(NSError *error) {
        assetError = [error retain];
        dispatch_semaphore_signal(sema);
    }];
    
    if ([NSThread isMainThread]) {
        while (!result && !assetError) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
    else {
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    
    dispatch_release(sema);
    [assetError release];
    [assetsLibrary release];
    
    return [result autorelease];
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
