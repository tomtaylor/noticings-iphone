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

@interface StreamPhoto : NSObject<NSCoding> {
    // NSDictionary describing the photo as returned by the API. Don't bother exploding it.
    NSDictionary *details;
}

- (id)initWithDictionary:(NSDictionary*)dict;

#define StreamPhotoVisibilityPublic 0
#define StreamPhotoVisibilityLimited 1
#define StreamPhotoVisibilityPrivate 2

@property (retain) NSDictionary *details;

// method/properties that extract information from datails dict.
@property (readonly) NSString* title;
@property (readonly) NSString* description;
@property (readonly) NSString* ownername;
@property (readonly) NSString* ago;
@property (readonly) NSString* placename;
@property (readonly) int visibility;
@property (readonly) NSURL* avatarURL;
@property (readonly) NSURL* imageURL;

@end
