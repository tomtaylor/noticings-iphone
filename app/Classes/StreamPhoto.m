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

- (id)initWithDictionary:(NSDictionary*)dict;
{
    self = [super init];
    if (self) {
        self.details = [dict copy];
    }
    return self;
}

- (NSString*)title;
{
    return [self.details valueForKeyPath:@"title"];
}

- (NSString*)description;
{
    NSString* raw = [self.details valueForKeyPath:@"description._text"];
    if (raw == nil) {
        return nil;
    }
    NSRange r;
    NSString *s = [[raw copy] autorelease];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    }
    s = [s stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@"&"];
    //s = [s stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSLog(@"done - got:\n%@", s);
    return s;
}


- (NSString*)ownername;
{
    return [self.details valueForKeyPath:@"ownername"];
}

- (NSString*)placename;
{
    return [self.details valueForKeyPath:@"ownername"];
}

- (NSURL*) imageURL;
{
    OFFlickrAPIContext *apiContext = [[[OFFlickrAPIContext alloc] initWithAPIKey:FLICKR_API_KEY sharedSecret:FLICKR_API_SECRET] autorelease];
    return [apiContext photoSourceURLFromDictionary:self.details size:@"m"];
}

- (NSURL*) avatarURL;
{
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
    return [NSURL URLWithString:avatarUrl];
}

- (NSString*) ago;
{
    NSTimeInterval epoch = [[NSDate date] timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970; // yeah.
    NSString *uploaded = [self.details objectForKey:@"dateupload"];
    if (!uploaded) {
        return @"";
    }
    int ago = epoch - [uploaded doubleValue]; // woooo overflow bug. I hope your friends upload at least once every 2*32 seconds!
    
    int seconds = ago % 60;
    int minutes = (ago / 60) % 60;
    int hours = (ago / (60*60)) % 24;
    int days = (ago / (24*60*60));
    
    if (days) {
        return [NSString stringWithFormat:@"%dd", days];
    }
    if (hours) {
        return [NSString stringWithFormat:@"%dh", hours];
    }
    if (minutes) {
        return [NSString stringWithFormat:@"%dm", minutes];
    }
    return [NSString stringWithFormat:@"%ds", seconds];
}


- (void)dealloc
{
    [super dealloc];
}

@end
