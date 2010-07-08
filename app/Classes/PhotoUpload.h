//
//  PhotoUpload.h
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Photo.h"

#define PhotoUploadStatePending @"pending"
#define PhotoUploadStateUploading @"uploading"
#define PhotoUploadStateSettingTimestamp @"settingTimestamp"
#define PhotoUploadStateSettingLocation @"settingLocation"
#define PhotoUploadStateSettingPermissions @"settingPermissions"
#define PhotoUploadStateComplete @"complete"

@interface PhotoUpload : NSObject <MKAnnotation> {
	Photo *photo;
	NSString *title;
	NSString *tags;
	NSNumber *progress;
	NSString *state;
	NSString *flickrId;
	NSDate *timestamp;
	CLLocationCoordinate2D coordinate;
}

@property (nonatomic, retain) Photo *photo;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *tags;
@property (nonatomic, retain) NSNumber *progress;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *flickrId;
@property (nonatomic, retain) NSDate *timestamp;
@property (nonatomic) CLLocationCoordinate2D coordinate;

- (id)initWithPhoto:(Photo *)_photo;
- (NSDictionary *)asDictionary;

@end