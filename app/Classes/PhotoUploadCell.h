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

// gratuitously NOT properties named like superclass!!
@property (strong, nonatomic) IBOutlet UIImageView* uploadImageView;
@property (strong, nonatomic) IBOutlet UILabel* mainTextLabel;
@property (strong, nonatomic) IBOutlet UILabel* otherTextLabel;
@property (strong, nonatomic) IBOutlet UIProgressView* progressView;

@end
