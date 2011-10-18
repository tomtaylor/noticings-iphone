//
//  StreamPhoto.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
// Represents a photo in the stream of "other people's photos".
//

#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@interface StreamPhoto : NSObject<NSCoding, MKAnnotation> {
    // NSDictionary describing the photo as returned by the API. Don't bother exploding it.
    NSDictionary *details;
}

- (id)initWithDictionary:(NSDictionary*)dict;

#define StreamPhotoVisibilityPublic 0
#define StreamPhotoVisibilityLimited 1
#define StreamPhotoVisibilityPrivate 2

@property (retain) NSDictionary *details;

// method/properties that extract information from datails dict.
@property (nonatomic, readonly, copy) NSString *title;
@property (readonly) NSString* flickrId;
@property (readonly) NSString* html;
@property (readonly) NSString* description;
@property (readonly) NSString* ownername;
@property (readonly) NSString* ownerId;
@property (readonly) NSString* ago;
@property (readonly) NSString* placename;
@property (readonly) NSString* woeid;
@property (readonly) int visibility;
@property (readonly) float latitude;
@property (readonly) float longitude;

@property (readonly) NSURL* avatarURL;
@property (readonly) NSURL* imageURL;
@property (readonly) NSURL* mapPageURL;
@property (readonly) NSURL* mapImageURL;
@property (readonly) BOOL hasLocation;
@property (readonly) NSURL* pageURL;
@property (readonly) NSURL* mobilePageURL;
@property (readonly) NSURL* bigImageURL;
@property (readonly) NSURL* originalImageURL;
@property (readonly) NSArray* tags;

// MKAnnotation
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *subtitle;

-(CGFloat)imageHeightForWidth:(CGFloat)width;
- (NSString*)titleOrUntitled;

@end
