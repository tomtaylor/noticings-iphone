//
//  DeferredFlickrCall.h
//  Noticings
//
//  Created by Tom Insam on 03/10/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import <Foundation/Foundation.h>
#import "CacheURLProtocol.h"

@interface DeferredFlickrCallManager : NSObject

typedef void (^FlickrSuccessCallback)(NSDictionary *rsp);
typedef void (^FlickrFailureCallback)(NSString *code, NSString *err);
typedef void (^FlickrCallback)(BOOL success, NSDictionary *rsp, NSError *error);

-(NSDictionary *) callSynchronousFlickrMethod:(NSString*)method asPost:(BOOL)asPost withArgs:(NSDictionary*)args error:(NSError**)errorAddr;
-(void)callFlickrMethod:(NSString*)method asPost:(BOOL)asPost withArgs:(NSDictionary*)args andThen:(FlickrCallback)callback;
-(void)callFlickrMethod:(NSString*)method asPost:(BOOL)asPost withArgs:(NSDictionary*)args andThen:(FlickrSuccessCallback)success orFail:(FlickrFailureCallback)failure;

@property (strong) NSOperationQueue *queue;

@end
