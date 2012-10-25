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

@interface StreamPhoto : NSManagedObject<MKAnnotation>

+ (id)photoWithDictionary:(NSDictionary*)dict;
+ (id)photoWithFlickrId:(NSString*)flickrId;

#define StreamPhotoVisibilityPublic 0
#define StreamPhotoVisibilityLimited 1
#define StreamPhotoVisibilityPrivate 2

-(void)updateFromPhotoInfo:(NSDictionary*)info;

// core data properties. Magic.
@property (nonatomic, strong) NSString *flickrId;
@property (nonatomic, strong) NSData *json;
@property (nonatomic, strong) NSData *fullInfo;
@property (nonatomic, strong) NSNumber *lastupdate;
@property (nonatomic, strong) NSNumber *dateupload;
@property (nonatomic, strong) NSNumber *needsFetch;
@property (nonatomic, strong) NSNumber *isfavorite;
@property (nonatomic, strong) NSNumber *comments;

// expanded JSON
@property (nonatomic, strong) NSDictionary *details;

// method/properties that extract information from datails dict.
@property (nonatomic, readonly, copy) NSString *title;
@property (weak, readonly) NSString* html;
@property (weak, readonly) NSString* ownername;
@property (weak, readonly) NSString* ownerId;
@property (weak, readonly) NSString* ago;
@property (weak, readonly) NSString* placename;
@property (weak, readonly) NSString* woeid;
@property (readonly) int visibility;
@property (readonly) float latitude;
@property (readonly) float longitude;
@property (weak, readonly) NSURL* avatarURL;
@property (weak, readonly) NSURL* imageURL;
@property (weak, readonly) NSURL* mapPageURL;
@property (weak, readonly) NSURL* mapImageURL;
@property (readonly) BOOL hasLocation;
@property (readonly) BOOL hasTitle;
@property (weak, readonly) NSURL* pageURL;
@property (weak, readonly) NSURL* mobilePageURL;
@property (weak, readonly) NSURL* bigImageURL;
@property (weak, readonly) NSURL* originalImageURL;
@property (weak, readonly) NSArray* tags;
@property (weak, readonly) NSArray* humanTags;

// MKAnnotation
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *subtitle;

-(CGFloat)imageHeightForWidth:(CGFloat)width;

@end
