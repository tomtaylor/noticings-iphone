//
//  DeferredFlickrCall.m
//  Noticings
//
//  Created by Tom Insam on 03/10/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "DeferredFlickrCallManager.h"
#import "SynthesizeSingleton.h"

#import "APIKeys.h"
#import "OFXMLMapper.h"
#import "ObjectiveFlickr.h"
#import "ASIHTTPRequest.h"


// leak internal signing method out from objective flickr. Yes. I am
// a bad person.
@interface OFFlickrAPIContext (LeakPrivateMethods)
- (NSString *)signedQueryFromArguments:(NSDictionary *)inArguments;
@end

@implementation DeferredFlickrCallManager
SYNTHESIZE_SINGLETON_FOR_CLASS(DeferredFlickrCallManager);

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
    NSString* token = [[NSUserDefaults standardUserDefaults] stringForKey:@"authToken"];
    return (!!token);
}

-(void)callFlickrMethod:(NSString*)method withArgs:(NSDictionary*)args andThen:(FlickrSuccessCallback)success orFail:(FlickrFailureCallback)failure;
{
    OFFlickrAPIContext *apiContext = [[OFFlickrAPIContext alloc] initWithAPIKey:FLICKR_API_KEY sharedSecret:FLICKR_API_SECRET];

    NSString* token = [[NSUserDefaults standardUserDefaults] stringForKey:@"authToken"];
    if (token) {
        [apiContext setAuthToken:token];
    }

    NSMutableDictionary *newArgs = args ? [NSMutableDictionary dictionaryWithDictionary:args] : [NSMutableDictionary dictionary];
	[newArgs setObject:method forKey:@"method"];	
	NSString *arguments = [apiContext signedQueryFromArguments:newArgs]; // private method
    NSURL *endpoint = [NSURL URLWithString:[apiContext RESTAPIEndpoint]];
    [apiContext release];
    
    // assume GET for now. We don't need post.
    NSString *URLString = [NSString stringWithFormat:@"%@?%@", endpoint, arguments];

    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URLString]];

    // for future reference:
    // NSData *postData = [arguments dataUsingEncoding:NSUTF8StringEncoding];
    //[request setPostBody:[NSMutableData dataWithData:postData]];
    
    [request setCompletionBlock:^{
        //NSLog(@"got response to %@", method);
        NSDictionary *responseDictionary = [OFXMLMapper dictionaryMappedFromXMLData:[request responseData]];	
        NSDictionary *rsp = [responseDictionary objectForKey:@"rsp"];
        NSString *stat = [rsp objectForKey:@"stat"];
        
        // this also fails when (responseDictionary, rsp, stat) == nil, so it's a guranteed way of checking the result
        if (![stat isEqualToString:@"ok"]) {
            NSDictionary *err = [rsp objectForKey:@"err"];
            NSString *code = [err objectForKey:@"code"];
            NSString *msg = [err objectForKey:@"msg"];
            NSLog(@"Failed flickr call %@(%@): %@ %@", method, args, code, msg);
            if (failure) {
                failure(code, msg);
            }
        } else {
            if (success) {
                success(rsp);
            }
        }
    }];
    
    [request setFailedBlock:^{
        NSLog(@"Failed ASIHTTPRequest call %@(%@): %@", method, args, [request error]);
        if (failure) {
            failure(@"", [[request error] localizedDescription]);
        }
    }];
    
    [self.queue addOperation:request];
    
    

    
}

-(void)dealloc;
{
    [self.queue cancelAllOperations];
    [super dealloc];
}

@end
