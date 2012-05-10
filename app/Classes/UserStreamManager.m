//
//  UserStreamManager.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "UserStreamManager.h"
#import "NoticingsAppDelegate.h"

@implementation UserStreamManager

@synthesize userId;

-(id)initWithUser:(NSString*)_userId;
{
    self = [super init];
    if (self) {
        self.userId = _userId;
        [self loadCachedImageList];
    }
    return self;
}


-(void)callFlickrAnd:(FlickrCallback)callback;
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"50", @"per_page",
                          [self extras], @"extras",
                          self.userId, @"user_id",
                          nil];
    [[NoticingsAppDelegate delegate].flickrCallManager callFlickrMethod:@"flickr.photos.search"
                                                                           asPost:NO
                                                                         withArgs:args
                                                                          andThen:callback];
}

-(NSString*)cacheFilename;
{
    if (!self.userId) {
        return @"";
    }
    return [NSString stringWithFormat:@"user-%@", self.userId];
}

-(void)dealloc;
{
    self.userId = nil;
    [super dealloc];
}

@end
