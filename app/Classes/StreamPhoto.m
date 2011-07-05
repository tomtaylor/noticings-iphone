//
//  StreamPhoto.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamPhoto.h"

#import "FlickrAPIKeys.h"
#import "ObjectiveFlickr.h"


@implementation StreamPhoto

@synthesize details;
@synthesize imageData;
@synthesize avatarData;

- (id)initWithDictionary:(NSDictionary*)dict;
{
    self = [super init];
    if (self) {
        self.details = [dict copy];
        
    }
    
    return self;
}

- (void) loadImageData;
{
    OFFlickrAPIContext *apiContext = [[OFFlickrAPIContext alloc] initWithAPIKey:FLICKR_API_KEY sharedSecret:FLICKR_API_SECRET];

    NSURL *imageUrl = [apiContext photoSourceURLFromDictionary:self.details size:@"m"];
    self.imageData = [NSData dataWithContentsOfURL:imageUrl];

    NSString *avatarUrl;
    if ([self.details objectForKey:@"iconserver"]) {
        avatarUrl = [NSString stringWithFormat:@"http://farm%@.static.flickr.com/%@/buddyicons/%@.jpg",
                     [self.details objectForKey:@"iconfarm"],
                     [self.details objectForKey:@"iconserver"],
                     [self.details objectForKey:@"owner"]
        ];
    } else {
        avatarUrl = @"http://www.flickr.com/images/buddyicon.jpg";
    }
    self.avatarData = [NSData dataWithContentsOfURL:[NSURL URLWithString:avatarUrl]];
    
    [apiContext release];
}

- (NSString*)title;
{
    return [self.details valueForKeyPath:@"title"];
}

- (NSString*)ownername;
{
    return [self.details valueForKeyPath:@"ownername"];
}

- (void)dealloc
{
    [super dealloc];
}

@end
