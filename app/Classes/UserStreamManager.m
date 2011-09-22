//
//  UserStreamManager.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "UserStreamManager.h"

@implementation UserStreamManager

@synthesize userId;

-(id)initWithUser:(NSString*)_userId;
{
    self = [super init];
    if (self) {
        self.userId = _userId;
    }
    return self;
}


-(void) callFlickr;
{
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"50", @"per_page",
                          [self extras], @"extras",
                          self.userId, @"user_id",
                          nil];
    [[self flickrRequest] callAPIMethodWithGET:@"flickr.photos.search" arguments:args];
}

@end
