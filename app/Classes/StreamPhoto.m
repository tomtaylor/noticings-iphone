//
//  StreamPhoto.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamPhoto.h"

#import "APIKeys.h"
#import "ObjectiveFlickr.h"

@implementation StreamPhoto

@synthesize details;

- (id)initWithDictionary:(NSDictionary*)dict;
{
    self = [super init];
    if (self) {
        self.details = dict;
    }
    return self;
}

#pragma mark accessors / view utilities

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
    // strip HTML tags and their contents from the response.
    NSRange r;
    NSString *s = [[raw copy] autorelease];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    }
    s = [s stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@"&"];
    return s;
}


- (NSString*)ownername;
{
    return [self.details valueForKeyPath:@"ownername"];
}

- (NSString*)placename;
{
    float lat = [[self.details valueForKey:@"latitude"] floatValue];
    float lng = [[self.details valueForKey:@"longitude"] floatValue];
    if (lat == 0 || lng == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"%.3f,%.3f", lat, lng];
}

- (NSURL*) imageURL;
{
    OFFlickrAPIContext *apiContext = [[[OFFlickrAPIContext alloc] initWithAPIKey:FLICKR_API_KEY sharedSecret:FLICKR_API_SECRET] autorelease];
    return [apiContext photoSourceURLFromDictionary:self.details size:nil];
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

- (NSURL*) pageURL;
{
    NSString *urlString = [NSString stringWithFormat:@"http://www.flickr.com/photos/%@/%@",
                           [self.details objectForKey:@"pathalias"],
                           [self.details objectForKey:@"id"]
                           ];
    return [NSURL URLWithString:urlString];
}

- (NSURL *)mobilePageURL;
{
    NSString *urlString = [NSString stringWithFormat:@"http://m.flickr.com/photos/%@/%@",
                           [self.details objectForKey:@"pathalias"],
                           [self.details objectForKey:@"id"]
                           ];
    return [NSURL URLWithString:urlString];
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

-(int)visibility;
{
    if ([[self.details objectForKey:@"ispublic"] intValue]) {
        return StreamPhotoVisibilityPublic;
    }
    if ([[self.details objectForKey:@"isfriend"] intValue] || [[self.details objectForKey:@"isfamily"] intValue]) {
        return StreamPhotoVisibilityLimited;
    }
    return StreamPhotoVisibilityPrivate;
}


-(CGFloat)imageHeightForWidth:(CGFloat)width;
{
    float width_m = [[self.details objectForKey:@"width_m"] floatValue];
    float height_m = [[self.details objectForKey:@"height_m"] floatValue];
    // if it's taller than square it won't fit in the view.
    return MIN( width * height_m / width_m, width );
}


#pragma mark serialize / deserizlise

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.details forKey:@"details"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.details = [coder decodeObjectForKey:@"details"];
    }
    return self;
}


#pragma mark memory managment

- (void)dealloc
{
    [super dealloc];
}

@end
