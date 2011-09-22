//
//  ContactsStreamManager.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ContactsStreamManager.h"
#import "SynthesizeSingleton.h"
#import "CacheManager.h"

@implementation ContactsStreamManager
SYNTHESIZE_SINGLETON_FOR_CLASS(ContactsStreamManager);

-(void) callFlickr;
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"50", @"count",
                          [self extras], @"extras",
                          @"1", @"include_self",
                          nil];
    [[self flickrRequest] callAPIMethodWithGET:@"flickr.photos.getContactsPhotos" arguments:args];
}


-(NSString*)cacheFilename;
{
    return @"contacts-images.cache";
}

@end
