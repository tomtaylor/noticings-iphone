//
//  PhotoUploadOperation.m
//  Noticings
//
//  Created by Tom Insam on 10/05/2012.
//  Copyright (c) 2012 Lanyrd. All rights reserved.
//

#import "PhotoUploadOperation.h"
#import "GCOAuth.h"
#import "NSString+URI.h"
#import "NoticingsAppDelegate.h"

@implementation PhotoUploadOperation

@synthesize upload = _upload,
            manager = _manager,
            requestLock = requestLock,
            requestFinished = _requestFinished,
            requestFailed = _requestFailed,
            responseData = _responseData;

#define BOUNDRY @"------------0x834758488ASDGC78A7896SFD"

-(id)initWithPhotoUpload:(PhotoUpload*)upload manager:(UploadQueueManager*)manager;
{
    // TODO - pause support. Fiangle the "isReady" key
    self = [super init];
    if (self) {
        self.upload = upload;
        self.manager = manager;
        self.upload.progress = 0;
    }
    return self;
}


-(void)fail:(NSError*)e;
{
    [self backout];
    dispatch_async(dispatch_get_main_queue(),^{
        [self.manager uploadFailed:self.upload];
    });
}

-(void)backout;
{
    // TODO - delete the uploaded photo, so we don't leave dangling images?

}

-(void)status:(float)progress;
{
    // call on main thread so KVO is safe for GUI elements
    dispatch_async(dispatch_get_main_queue(),^{
        self.upload.progress = [NSNumber numberWithFloat:progress];
        self.upload.inProgress = YES;
        [self.manager operationUpdated];
    });
}

-(void)main;
{
    // TODO - upload with progress. Respect 'cancel'.
    [self status:0];
    
    NSData *uploaddata = [self.upload imageData];
    if (!uploaddata) {
        return [self fail:nil];
    }
    
    if ([self isCancelled]) return [self backout];
    [self.manager operationUpdated];
    
    NSString *uploadedTitleString;
    if (self.upload.title == nil || [self.upload.title isEqualToString:@""]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        uploadedTitleString = [dateFormatter stringFromDate:self.upload.timestamp];
        [dateFormatter release];
    } else {
        uploadedTitleString = self.upload.title;
    }
    
    NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      uploadedTitleString, @"title", 
                                      self.upload.tags, @"tags",
                                      nil];
    
    if (self.upload.privacy == PhotoUploadPrivacyPrivate) {
        [arguments setObject:@"0" forKey:@"is_public"];
    } else if (self.upload.privacy == PhotoUploadPrivacyFriendsAndFamily) {
        [arguments setObject:@"1" forKey:@"is_friend"];
        [arguments setObject:@"1" forKey:@"is_family"];
        [arguments setObject:@"0" forKey:@"is_public"];
    } else {
        [arguments setObject:@"1" forKey:@"is_public"];
    }
    
    NSString* token = [[NSUserDefaults standardUserDefaults] stringForKey:@"oauth_token"];
    NSString* secret = [[NSUserDefaults standardUserDefaults] stringForKey:@"oauth_secret"];
    
    NSURLRequest *req = [GCOAuth URLRequestForPath:@"/services/upload"
                                    POSTParameters:arguments
                                            scheme:@"http"
                                              host:@"api.flickr.com"
                                       consumerKey:FLICKR_API_KEY
                                    consumerSecret:FLICKR_API_SECRET
                                       accessToken:token
                                       tokenSecret:secret];
    
    NSMutableURLRequest *myreq = [[req mutableCopy] autorelease];
    myreq.timeoutInterval = 100;
    
    // I DO NOT WANT TO TALK ABOUT THIS.
    [myreq setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", BOUNDRY] forHTTPHeaderField:@"Content-Type"];
    NSMutableData *postData = [NSMutableData dataWithCapacity:[uploaddata length] + 1024];
    [arguments enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *val, BOOL *stop) {
        [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", BOUNDRY] dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", [key stringByEncodingForURI]] dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[val dataUsingEncoding:NSUTF8StringEncoding]];
        [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", BOUNDRY] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"file.bin\"\r\n\r\n", @"photo"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:uploaddata];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", BOUNDRY] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [myreq setHTTPBody:postData];
    NSString *length = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    [myreq setValue:length forHTTPHeaderField:@"Content-Length"];

    if ([self isCancelled]) return [self backout];
    [self status:0];
    
    // make long-running request, blocking this thread, but sending status updates
    self.requestLock = [[[NSCondition alloc] init] autorelease];
    [self.requestLock lock];
    self.requestFinished = FALSE;
    
    __block NSURLConnection *connection;
    // NSURLConnection needs the main thread runloop. this is annoying.
    dispatch_async(dispatch_get_main_queue(),^{
        connection = [[NSURLConnection alloc] initWithRequest:myreq delegate:self startImmediately:YES];
    });
    while (!(self.requestFinished || self.requestFailed)) {
        DLog(@"waiting for upload to complete");
        [self.requestLock wait];
    }
    [connection release];
    
    if (self.requestFailed) return; // assume [self fail:] already called
    if ([self isCancelled]) return [self backout];
    if (!self.responseData) {
        DLog(@"no data from response");
        return [self fail:nil];
    }
    [self status:0.85];
    
    // response here is XML. Fuck.
    NSString *stringBody = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    self.responseData = nil;
    
    // I REALLY REALLY DON'T WANT TO TALK ABOUT THIS
    NSRange start = [stringBody rangeOfString:@"<photoid>"];
    NSRange end = [stringBody rangeOfString:@"</photoid>"];
    NSString *photoId = [stringBody substringWithRange:NSMakeRange(start.location + start.length, end.location - (start.location+start.length))];
    NSLog(@"Got photo ID %@", photoId);
    [stringBody release];
    

    self.upload.flickrId = photoId;

    
    // ##################################################
    // set timestamp

    if ([self isCancelled]) return [self backout];
    [self status:0.9];

    if (self.upload.timestamp != self.upload.originalTimestamp) {
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *timestampString = [outputFormatter stringFromDate:self.upload.timestamp];
        [outputFormatter release];
        
        NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.upload.flickrId, @"photo_id",
                                   timestampString, @"date_taken",
                                   nil];
        
        DeferredFlickrCallManager *callManager = [NoticingsAppDelegate delegate].flickrCallManager;
        NSError *error = nil;
        [callManager callSynchronousFlickrMethod:@"flickr.photos.setDates" asPost:YES withArgs:arguments error:&error];
        if (error) {
            return [self fail:error];
        }
    }
    

    // ##################################################
    // set location

    if ([self isCancelled]) return [self backout];
    [self status:0.95];
    
    // if the coordinate differs from what was set in the asset, then we update the geodata manually
    if (self.upload.coordinate.latitude != self.upload.originalCoordinate.latitude ||
        self.upload.coordinate.longitude != self.upload.originalCoordinate.longitude) {
        DeferredFlickrCallManager *callManager = [NoticingsAppDelegate delegate].flickrCallManager;
        
        if (CLLocationCoordinate2DIsValid(self.upload.coordinate)) {
            // set the geodata manually
            
            NSNumber *latitudeNumber = [NSNumber numberWithDouble:self.upload.coordinate.latitude];
            NSNumber *longitudeNumber = [NSNumber numberWithDouble:self.upload.coordinate.longitude];
            
            DLog(@"Setting latitude to %f, longitude to %f", self.upload.coordinate.latitude, self.upload.coordinate.longitude);
            
            NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:self.upload.flickrId, @"photo_id", 
                                       [latitudeNumber stringValue], @"lat",
                                       [longitudeNumber stringValue], @"lon",
                                       nil];
            
            NSError *error = nil;
            [callManager callSynchronousFlickrMethod:@"flickr.photos.geo.setLocation" asPost:YES withArgs:arguments error:&error];
            if (error) {
                return [self fail:error];
            }
            
        } else if (CLLocationCoordinate2DIsValid(self.upload.originalCoordinate)) {            
            // remove the geodata manually
            
            DLog(@"PhotoUpload did originally have a coordinate, but was removed the map, so removing the geodata manually.");
            NSDictionary *arguments = [NSDictionary dictionaryWithObject:self.upload.flickrId forKey:@"photo_id"];
            NSError *error = nil;
            [callManager callSynchronousFlickrMethod:@"flickr.photos.geo.removeLocation" asPost:YES withArgs:arguments error:&error];
            if (error) {
                return [self fail:error];
            }
        }
        
    }
    
    if ([self isCancelled]) return [self backout];
    [self status:1];
}


#pragma mark NSURLConnection data delegate methods

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    DLog(@"SENT %d bytes of %d", totalBytesWritten, totalBytesExpectedToWrite);
    // we get to go up to 0.80
    [self status:(0.80 * totalBytesWritten) / totalBytesExpectedToWrite];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
	// every response could mean a redirect
    DLog(@"got response");
    self.responseData = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
    DLog(@"got data in response to upload");
	if (!self.responseData) {
        self.responseData = [NSMutableData dataWithData:data];
	} else {
		[self.responseData appendData:data];
    }
}

// all worked
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
    DLog(@"upload complete");
    self.requestFinished = YES;
    [self.requestLock signal];
}

// and error occured
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
    DLog(@"upload failed");
    self.requestFailed = YES;
    [self fail:error];
    [self.requestLock signal];
}



@end
