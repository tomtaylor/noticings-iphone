//
//  DeferredFlickrCall.m
//  Noticings
//
//  Created by Tom Insam on 03/10/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import "DeferredFlickrCallManager.h"

#import "APIKeys.h"
#import "GCOAuth.h"
#import "JSONKit.h"

@implementation DeferredFlickrCallManager

@synthesize queue;

-(id)init;
{
    self = [super init];
    if (self) {
        self.queue = [[[NSOperationQueue alloc] init] autorelease];
        self.queue.maxConcurrentOperationCount = 2;
    }
    return self;
}

-(BOOL)hasAuthentication;
{
    NSString* token = [[NSUserDefaults standardUserDefaults] stringForKey:@"oauth_token"];
    return (!!token);
}

-(NSDictionary *) callSynchronousFlickrMethod:(NSString*)method asPost:(BOOL)asPost withArgs:(NSDictionary*)args error:(NSError**)errorAddr;
{
    NSMutableDictionary *newArgs = args ? [NSMutableDictionary dictionaryWithDictionary:args] : [NSMutableDictionary dictionary];
	newArgs[@"method"] = method;
	newArgs[@"format"] = @"json";
    newArgs[@"nojsoncallback"] = @"1";
    
    NSString* token = [[NSUserDefaults standardUserDefaults] stringForKey:@"oauth_token"];
    NSString* secret = [[NSUserDefaults standardUserDefaults] stringForKey:@"oauth_secret"];
    
    NSURLRequest *req;
    if (asPost) {
        req = [GCOAuth URLRequestForPath:@"/services/rest"
                          POSTParameters:newArgs
                                  scheme:@"http"
                                    host:@"api.flickr.com"
                             consumerKey:FLICKR_API_KEY
                          consumerSecret:FLICKR_API_SECRET
                             accessToken:token
                             tokenSecret:secret];
    } else {
        req = [GCOAuth URLRequestForPath:@"/services/rest"
                           GETParameters:newArgs
                                  scheme:@"http"
                                    host:@"api.flickr.com"
                             consumerKey:FLICKR_API_KEY
                          consumerSecret:FLICKR_API_SECRET
                             accessToken:token
                             tokenSecret:secret];
    }
    
    NSMutableURLRequest *myreq = [req mutableCopy];
    myreq.timeoutInterval = 100;
    
    NSHTTPURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:myreq returningResponse:&response error:errorAddr];
    [myreq release];
    
    if (*errorAddr) {
        return nil;
    }
    NSDictionary *rsp = [[JSONDecoder decoder] objectWithData:data error:errorAddr];
    if (*errorAddr) {
        return nil;
    }
    if (!rsp) {
        return nil;
    }
    if (![rsp[@"stat"] isEqualToString:@"ok"]) {
        NSLog(@"Failed flickr call %@(%@): %@", method, newArgs, rsp);
        NSString *code = rsp[@"code"];
        *errorAddr = [NSError errorWithDomain:@"flickr" code:[code integerValue] userInfo:rsp];
        return rsp;
    }
    return rsp;
}

-(void)callFlickrMethod:(NSString*)method asPost:(BOOL)asPost withArgs:(NSDictionary*)args andThen:(FlickrCallback)callback;
{
    [self.queue addOperationWithBlock:^{
        NSError *error = nil;
        NSDictionary *rsp = [self callSynchronousFlickrMethod:method asPost:asPost withArgs:args error:&error];
        dispatch_async(dispatch_get_main_queue(),^{
            if (error) {
                callback(NO, rsp, error);
            } else {
                callback(YES, rsp, nil);
            }
        });
    }];    
    
}

-(void)callFlickrMethod:(NSString*)method asPost:(BOOL)asPost withArgs:(NSDictionary*)args andThen:(FlickrSuccessCallback)successCB orFail:(FlickrFailureCallback)failure;
{
    [self callFlickrMethod:method asPost:asPost withArgs:args andThen:^(BOOL success, NSDictionary *rsp, NSError *error) {
        if (success) {
            successCB(rsp);
        } else {
            failure((error.userInfo)[@"code"], (error.userInfo)[@"msg"]);
        }
    }];
}

-(void)dealloc;
{
    [self.queue cancelAllOperations];
    [super dealloc];
}

@end
