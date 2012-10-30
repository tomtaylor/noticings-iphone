//
//  StarredStreamManager.m
//  Noticings
//
//  Created by Tom Insam on 2012/10/25.
//
//

#import "StarredStreamManager.h"
#import "NoticingsAppDelegate.h"

@implementation StarredStreamManager

-(void)callFlickrAnd:(FlickrCallback)callback;
{
    NSDictionary *args = @{
        @"per_page": @"50",
        @"extras": [self extras],
    };
    [[NoticingsAppDelegate delegate].flickrCallManager callFlickrMethod:@"flickr.favorites.getList"
                                                                 asPost:NO
                                                               withArgs:args
                                                                andThen:callback];
}

-(NSString*)cacheFilename;
{
    return @"starred";
}

@end
