//
//  TagStreamManager.m
//  Noticings
//
//  Created by Tom Insam on 05/10/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "TagStreamManager.h"

@implementation TagStreamManager

@synthesize tag;

-(id)initWithTag:(NSString*)_tag;
{
    self = [super init];
    if (self) {
        self.tag = _tag;
        [self loadCachedImageList];
    }
    return self;
}


-(void) callFlickr;
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"50", @"per_page",
                          [self extras], @"extras",
                          self.tag, @"tags",
                          nil];
    [[self flickrRequest] callAPIMethodWithGET:@"flickr.photos.search" arguments:args];
}

-(NSString*)cacheFilename;
{
    if (!self.tag) {
        return @"";
    }
    return [NSString stringWithFormat:@"tag-%@", self.tag];
}

-(void)dealloc;
{
    self.tag = nil;
    [super dealloc];
}

@end
