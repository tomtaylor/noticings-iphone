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

-(NSArray*)filteredPhotos;
{
    // there's a setting that will hide instagram photos.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"filterInstagram"]) {
        return [super filteredPhotos];
    }

    return [self.rawPhotos filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        StreamPhoto *sp = (StreamPhoto*)evaluatedObject;
        if ([sp.tags filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            NSString *tag = (NSString*)evaluatedObject;
            return [tag isEqualToString:@"uploaded:by=instagram"];
        }]].count > 0) {
            return NO;
        }
        return YES;
    }]];
}

-(NSString*)cacheFilename;
{
    return @"contacts-images.cache";
}

@end
