//
//  StreamManager.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamManager.h"
#import "StreamPhoto.h"

@implementation StreamManager

SYNTHESIZE_SINGLETON_FOR_CLASS(StreamManager);

@synthesize photos;
@synthesize inProgress;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.photos = [NSMutableArray arrayWithCapacity:50];
        self.inProgress = NO;
    }
    
    return self;
}

- (void)refresh;
{
    if (self.inProgress) {
        NSLog(@"scan in progress, refusing to go again.");
        return;
    }
    
    self.inProgress = YES;

    NSLog(@"refresh!");
    
    NSString *extras = @"date_upload,date_taken,owner_name,icon_server,geo,path_alias";
    
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"6", @"count",
                          extras, @"extras",
                          @"1", @"include_self",
                          nil];
    
    [[self flickrRequest] callAPIMethodWithGET:@"flickr.photos.getContactsPhotos" arguments:args];
}



// TODO - stolen from the uploader. refactor into base class?
- (OFFlickrAPIRequest *)flickrRequest;
{
	if (!flickrRequest) {
		OFFlickrAPIContext *apiContext = [[OFFlickrAPIContext alloc] initWithAPIKey:FLICKR_API_KEY
                                                                       sharedSecret:FLICKR_API_SECRET];
		[apiContext setAuthToken:[[NSUserDefaults standardUserDefaults] stringForKey:@"authToken"]];
		flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:apiContext];
		flickrRequest.delegate = self;
		flickrRequest.requestTimeoutInterval = 45;
		[apiContext release];
	}
	
	return flickrRequest;
}



#pragma mark Flickr delegate methods


- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
    NSLog(@"completed flickr request!");
    NSLog(@"got %@", inResponseDictionary);

    [self.photos removeAllObjects];
    for (NSDictionary *photo in [inResponseDictionary valueForKeyPath:@"photos.photo"]) {
        StreamPhoto *sp = [[StreamPhoto alloc] initWithDictionary:photo];
        [self.photos addObject:sp];
        [sp release];
    }
    
    self.inProgress = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"newPhotos"
                                                        object:[NSNumber numberWithInt:self.photos.count]];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
    NSLog(@"failed flickr request!");
}






- (void)dealloc
{
    self.photos = nil;
    [flickrRequest release];
    [super dealloc];
}

@end
