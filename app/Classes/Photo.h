//
//  Photo.h
//  Noticings
//
//  Created by Tom Taylor on 06/08/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface Photo : NSObject {
	ALAsset *asset;
	UIImage *thumbnail;
	NSDate *timestamp;
	CLLocation *location;
	BOOL noLocation;
}

@property (nonatomic, retain) ALAsset *asset;
@property (nonatomic, retain) NSDate *timestamp;
@property (nonatomic, retain) UIImage *thumbnailImage;
@property (nonatomic, retain) CLLocation *location;
@property (nonatomic, retain) NSData *imageData;

- (id) initWithAsset:(ALAsset *)anAsset;

@end
