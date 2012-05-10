//
//  DeferredFlickrCall.m
//  Noticings
//
//  Created by Tom Insam on 03/10/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "DeferredFlickrCallManager.h"

#import "APIKeys.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
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

-(void)callFlickrMethod:(NSString*)method asPost:(BOOL)asPost withArgs:(NSDictionary*)args andThen:(FlickrCallback)callback;
{
    NSMutableDictionary *newArgs = args ? [NSMutableDictionary dictionaryWithDictionary:args] : [NSMutableDictionary dictionary];
	[newArgs setObject:method forKey:@"method"];
	[newArgs setObject:@"json" forKey:@"format"];
    [newArgs setObject:@"1" forKey:@"nojsoncallback"];
    
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
    
    [self.queue addOperationWithBlock:^{
        NSHTTPURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:myreq returningResponse:&response error:&error];
        NSDictionary *rsp = [NSDictionary dictionary];
        if (!error) {
            rsp = [[JSONDecoder decoder] objectWithData:data error:&error];
        }
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (error) {
                callback(NO, nil, error);
            } else if (response.statusCode == 200 && rsp && [[rsp objectForKey:@"stat"] isEqualToString:@"ok"]) {
                // response is ok
                callback(YES, rsp, nil);
                
            } else {
                // not ok
                NSDictionary *err = [rsp objectForKey:@"err"];
                NSString *code = [err objectForKey:@"code"];
                NSString *msg = [err objectForKey:@"msg"];
                NSLog(@"Failed flickr call %@(%@):\n  - %@ %@", method, newArgs, code, msg);
                callback(NO, rsp, [NSError errorWithDomain:@"flickr" code:[code integerValue] userInfo:err]);
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
            failure([error.userInfo objectForKey:@"code"], [error.userInfo objectForKey:@"msg"]);
        }
    }];
}

-(void)dealloc;
{
    [self.queue cancelAllOperations];
    [super dealloc];
}

@end
