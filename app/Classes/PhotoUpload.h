//
//  PhotoUpload.h
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

enum {
    PhotoUploadPrivacyPrivate,
    PhotoUploadPrivacyFriendsAndFamily,
    PhotoUploadPrivacyPublic
};

@interface PhotoUpload : NSObject <MKAnnotation, NSCoding> {
}

@property (nonatomic, retain) ALAsset *asset;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, retain) NSString *tags;
@property (nonatomic, retain) NSNumber *progress;
@property (nonatomic) BOOL inProgress;
@property (nonatomic) NSInteger privacy;
@property (nonatomic, retain) NSString *flickrId;
@property (nonatomic, retain) CLLocation *location;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) CLLocationCoordinate2D originalCoordinate;
@property (nonatomic, retain) NSDate *timestamp;
@property (nonatomic, retain) NSDate *originalTimestamp;


- (id)initWithAsset:(ALAsset *)asset;
//- (id)initWithDictionary:(NSDictionary *)dictionary;
//- (NSDictionary *)asDictionary;
- (NSData *)imageData;

@end