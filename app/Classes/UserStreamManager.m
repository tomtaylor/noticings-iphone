//
//  UserStreamManager.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Tom Insam.
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
    NSDictionary *args = @{@"per_page": @"50",
                          @"extras": [self extras],
                          @"user_id": self.userId};
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
