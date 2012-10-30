//
//  PhotoLocationManager.h
//  Noticings
//
//  Created by Tom Insam on 30/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import <Foundation/Foundation.h>
#import "StreamPhoto.h"

@protocol LocationDelegate <NSObject>
@required
-(void) gotLocation:(NSString*)location forPhoto:(StreamPhoto*)photo;
@end


@interface PhotoLocationManager : NSObject

typedef void (^LocationCallbackBlock)(NSString* name);

-(NSString*)cachedLocationForPhoto:(StreamPhoto*)photo;
-(void)getLocationForPhoto:(StreamPhoto*)photo andTell:(NSObject<LocationDelegate>*)delegate;
-(NSMutableDictionary*)loadCachedLocations;
-(void)saveCachedLocations:(NSMutableDictionary*)cache;

@property (strong) NSOperationQueue *queue;
@property (strong) NSMutableDictionary *cache;
@property (strong) NSMutableDictionary *locationRequests;

@end
