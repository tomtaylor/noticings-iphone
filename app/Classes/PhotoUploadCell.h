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

@property (nonatomic, strong) PhotoUpload *photoUpload;

- (void)displayPhotoUpload:(PhotoUpload *)photoUpload;

@property (strong, nonatomic) IBOutlet UIImageView* imageView;
@property (strong, nonatomic) IBOutlet UILabel* textLabel;
@property (strong, nonatomic) IBOutlet UILabel* detailTextLabel;
@property (strong, nonatomic) IBOutlet UIProgressView* progressView;
@property (strong, nonatomic) IBOutlet UIImage *notAButton;

@end
