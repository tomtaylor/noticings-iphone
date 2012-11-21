//
//  PhotoUpload.m
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoUpload.h"
#import "UIImage+Resize.h"

@implementation PhotoUpload

enum {
    ASSETURL_PENDINGREADS = 1,
    ASSETURL_ALLFINISHED = 0
};

-(NSString*)description;
{
    // this is the objective C introspection / toString() method
    return [NSString stringWithFormat:@"<%@ \"%@\" progress %@>", self.class, self.title, self.paused ? @"PAUSED" : self.progress];
}

// TODO - not really happy moving UIImage objects around here. These images might be really big!

-(id)initWithImage:(UIImage *)image location:(CLLocation*)location timestamp:(NSDate*)timestamp;
{
    self = [super init];
    if (self != nil) {
        self.inProgress = FALSE;
        self.paused = FALSE;
		self.progress = @0.0f;
        self.uploadStatus = nil;
        self.privacy = PhotoUploadPrivacyPublic;

        self.image = image;
        self.thumbnail = [image resizedImageWithWidth:128 AndHeight:128]; // TODO - use correct numbers. Also retina-aware
        self.timestamp = timestamp;
        self.originalTimestamp = timestamp;

        self.location = location;
        if (self.location != nil) {
			self.originalCoordinate = self.location.coordinate;
		} else {
			self.originalCoordinate = kCLLocationCoordinate2DInvalid;
		}
        self.coordinate = self.originalCoordinate;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:4 forKey:@"version"];
    [coder encodeObject:self.image forKey:@"image"];
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.tags forKey:@"tags"];
    [coder encodeInt:self.privacy forKey:@"privacy"];
    [coder encodeObject:self.flickrId forKey:@"flickrId"];
    [coder encodeObject:self.location forKey:@"location"];
    [coder encodeObject:self.timestamp forKey:@"timestamp"];
    [coder encodeObject:self.originalTimestamp forKey:@"originalTimestamp"];
    [coder encodeDouble:self.coordinate.latitude forKey:@"coordinate.latitude"];
    [coder encodeDouble:self.coordinate.longitude forKey:@"coordinate.longitude"];
    [coder encodeDouble:self.originalCoordinate.latitude forKey:@"originalCoordinate.latitude"];
    [coder encodeDouble:self.originalCoordinate.longitude forKey:@"originalCoordinate.longitude"];
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
        // TODO images probably too big for this
        self.image = [decoder decodeObjectForKey:@"image"];
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
        self.coordinate = aCoordinate;
        
        CLLocationCoordinate2D anOriginalCoordinate;
        anOriginalCoordinate.latitude = [decoder decodeDoubleForKey:@"originalCoordinate.latitude"];
        anOriginalCoordinate.longitude = [decoder decodeDoubleForKey:@"originalCoordinate.longitude"];
        self.originalCoordinate = anOriginalCoordinate;
                
        self.inProgress = NO;
		self.progress = @0.0f;
        self.paused = YES;
    }
    return self;
}


@end
