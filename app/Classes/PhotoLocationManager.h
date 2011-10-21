//
//  PhotoLocationManager.h
//  Noticings
//
//  Created by Tom Insam on 30/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamPhoto.h"
#import "ASIHTTPRequest.h"

@protocol LocationDelegate <NSObject>
@required
-(void) gotLocation:(NSString*)location forPhoto:(StreamPhoto*)photo;
@end


@interface PhotoLocationManager : NSObject

+(PhotoLocationManager*)sharedPhotoLocationManager;

typedef void (^LocationCallbackBlock)(NSString* name);

-(NSString*)cachedLocationForPhoto:(StreamPhoto*)photo;
-(void)getLocationForPhoto:(StreamPhoto*)photo andTell:(NSObject<LocationDelegate>*)delegate;
-(NSMutableDictionary*)loadCachedLocations;
-(void)saveCachedLocations:(NSMutableDictionary*)cache;

@property (retain) NSOperationQueue *queue;
@property (retain) NSMutableDictionary *cache;
@property (retain) NSMutableDictionary *locationRequests;

@end
