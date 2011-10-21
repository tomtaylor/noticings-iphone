//
//  DeferredFlickrCall.h
//  Noticings
//
//  Created by Tom Insam on 03/10/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeferredFlickrCallManager : NSObject

typedef void (^FlickrSuccessCallback)(NSDictionary *rsp);
typedef void (^FlickrFailureCallback)(NSString *code, NSString *err);

+(DeferredFlickrCallManager*)sharedDeferredFlickrCallManager;

-(void)callFlickrMethod:(NSString*)method asPost:(BOOL)asPost withArgs:(NSDictionary*)args andThen:(FlickrSuccessCallback)success orFail:(FlickrFailureCallback)failure;

@property (retain) NSOperationQueue *queue;
@property (retain) NSOperationQueue *xmlQueue;

@end
