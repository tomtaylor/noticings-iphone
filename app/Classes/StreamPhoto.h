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

@interface StreamPhoto : NSObject {
    
    // NSDictionary describing the photo as returned by the API. Don't bother exploding it.
    NSDictionary *details;
    NSData *avatarData;
    NSData *imageData;
    
}

- (id)initWithDictionary:(NSDictionary*)dict;
- (void) loadImageData;

@property (readonly) NSString* title;
@property (readonly) NSString* ownername;

@property (retain) NSDictionary *details;
@property (retain) NSData *imageData;
@property (retain) NSData *avatarData;

@end
