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
#import "NSString+HTML.h"

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

- (NSString*)flickrId;
{
    return [self.details valueForKeyPath:@"id"];
}

- (NSString*)title;
{
    return [self.details valueForKeyPath:@"title"];
}

- (NSString*)html;
{
    NSString *raw = [self.details valueForKeyPath:@"description._text"];
    return [raw stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
}

- (NSString*)description;
{
    NSString *raw = [self.details valueForKeyPath:@"description._text"];
    return [raw stringByConvertingHTMLToPlainText];
}


- (NSString*)ownername;
{
    return [self.details valueForKeyPath:@"ownername"];
}

- (NSString*)ownerId;
{
    return [self.details valueForKeyPath:@"owner"];
}

-(float)latitude;
{
    return [[self.details valueForKey:@"latitude"] floatValue];
}

-(float)longitude;
{
    return [[self.details valueForKey:@"longitude"] floatValue];
}

-(BOOL)hasLocation;
{
    float lat = [[self.details valueForKey:@"latitude"] floatValue];
    float lng = [[self.details valueForKey:@"longitude"] floatValue];
    return (lat != 0 && lng != 0);
}

- (NSString*)placename;
{
    return [NSString stringWithFormat:@"%.3f,%.3f", self.latitude, self.longitude];
}

- (NSString*)woeid;
{
    return [self.details valueForKey:@"woeid"];
}

- (NSURL*) mapPageURL;
{
    NSString *title = [self.title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (title.length == 0) {
        title = @"Photo"; // google maps needs something
    }
    NSString *mapURL = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%f,%f+(%@)", self.latitude, self.longitude, title];
    return [NSURL URLWithString:mapURL];
}

-(NSURL*)mapImageURL;
{
    int scale = [UIScreen mainScreen].scale; //  1 or 2
    NSString *mapURL = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/staticmap?sensor=false&size=310x90&center=%f,%f&zoom=13&scale=%d&markers=size:small%%7C%f,%f",
                        self.latitude, self.longitude, scale, self.latitude, self.longitude];
    return [NSURL URLWithString:mapURL];
}

- (NSURL*) imageURL;
{
    OFFlickrAPIContext *apiContext = [[[OFFlickrAPIContext alloc] initWithAPIKey:FLICKR_API_KEY sharedSecret:FLICKR_API_SECRET] autorelease];
    return [apiContext photoSourceURLFromDictionary:self.details size:nil];
}

- (NSURL*) bigImageURL;
{
    OFFlickrAPIContext *apiContext = [[[OFFlickrAPIContext alloc] initWithAPIKey:FLICKR_API_KEY sharedSecret:FLICKR_API_SECRET] autorelease];
    return [apiContext photoSourceURLFromDictionary:self.details size:@"b"];
}

- (NSURL*) originalImageURL;
{
    if ([self.details valueForKey:@"url_o"]) {
        return [NSURL URLWithString:[self.details valueForKey:@"url_o"]];
    } else {
        return self.bigImageURL;
    }
}

- (NSURL*) avatarURL;
{
    NSString *avatarUrl;
    if ([self.details objectForKey:@"iconserver"] && ![[self.details objectForKey:@"iconserver"] isEqual:@"0"]) {
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

-(NSArray*)tags;
{
    NSString *tags = [self.details valueForKey:@"tags"];
    if (tags.length > 0) {
        return [tags componentsSeparatedByString:@" "];
    }
    return [NSArray array];
}



-(CGFloat)imageHeightForWidth:(CGFloat)width;
{
    float width_m = [[self.details objectForKey:@"width_m"] floatValue];
    float height_m = [[self.details objectForKey:@"height_m"] floatValue];
    CGFloat height = width * height_m / width_m;
    return height;
}



#pragma mark MKAnnotation

-(CLLocationCoordinate2D)coordinate;
{
    CLLocationCoordinate2D location;
    location.latitude = self.latitude;
    location.longitude = self.longitude;
    return location;
}

- (NSString*)subtitle;
{
    return [self.details valueForKeyPath:@"ownername"];
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
