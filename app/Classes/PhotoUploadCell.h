//
//  PhotoUploadCell.h
//  Noticings
//
//  Created by Tom Taylor on 27/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoUpload.h"


@interface PhotoUploadCell : UITableViewCell <UIActionSheetDelegate>

@property (nonatomic, retain) PhotoUpload *photoUpload;

- (void)displayPhotoUpload:(PhotoUpload *)photoUpload;

@property (retain, nonatomic) IBOutlet UIImageView* imageView;
@property (retain, nonatomic) IBOutlet UILabel* textLabel;
@property (retain, nonatomic) IBOutlet UILabel* detailTextLabel;
@property (retain, nonatomic) IBOutlet UIProgressView* progressView;
@property (retain, nonatomic) IBOutlet UIImage *notAButton;

@end
