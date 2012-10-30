//
//  TagStreamManager.m
//  Noticings
//
//  Created by Tom Insam on 05/10/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import "TagStreamManager.h"

@implementation TagStreamManager

-(id)initWithTag:(NSString*)tag;
{
    self = [super init];
    if (self) {
        self.tag = tag;
        [self loadCachedImageList];
    }
    return self;
}


-(void) callFlickr;
{
//    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
//                          @"50", @"per_page",
//                          [self extras], @"extras",
//                          self.tag, @"tags",
//                          nil];
//    [[self flickrRequest] callAPIMethodWithGET:@"flickr.photos.search" arguments:args];
}

-(NSString*)cacheFilename;
{
    if (!self.tag) {
        return @"";
    }
    return [NSString stringWithFormat:@"tag-%@", self.tag];
}


@end
