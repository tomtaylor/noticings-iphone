//
//  PhotoUploadCell.h
//  Noticings
//
//  Created by Tom Taylor on 27/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoUpload.h"


@interface PhotoUploadCell : UITableViewCell {
	PhotoUpload *photoUpload;
	NSNumberFormatter *percentFormatter;
}

@property (nonatomic, retain) PhotoUpload *photoUpload;

- (id)initWithPhotoUpload:(PhotoUpload *)_photoUpload;

@end
