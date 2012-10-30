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

@interface PhotoUpload : NSObject <MKAnnotation, NSCoding>

@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSString *tags;
@property (nonatomic, strong) NSNumber *progress;
@property (nonatomic) BOOL inProgress;
@property (nonatomic) BOOL paused;
@property (nonatomic) NSInteger privacy;
@property (nonatomic, strong) NSString *flickrId;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) CLLocationCoordinate2D originalCoordinate;
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, strong) NSDate *originalTimestamp;


- (id)initWithAsset:(ALAsset *)asset;
- (NSData *)imageData;

@end