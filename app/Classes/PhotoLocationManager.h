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

@interface PhotoLocationManager : NSObject

+(PhotoLocationManager*)sharedPhotoLocationManager;

typedef void (^LocationCallbackBlock)(NSString* name);

-(void)getLocationForPhoto:(StreamPhoto*)photo and:(LocationCallbackBlock)block;
-(NSMutableDictionary*)loadCachedLocations;
-(void)saveCachedLocations:(NSMutableDictionary*)cache;

@property (retain) NSOperationQueue *queue;
@property (retain) NSMutableDictionary *cache;

@end
