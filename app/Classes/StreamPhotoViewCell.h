//
//  StreamPhotoViewCell.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamPhoto.h"
#import "CacheManager.h"
#import "PhotoLocationManager.h"

#define PADDING_SIZE 4.0f

@interface StreamPhotoViewCell : UITableViewCell <LocationDelegate> {
    
    IBOutlet UIImageView *avatarView;
    IBOutlet UIImageView *photoView;
    IBOutlet UIImageView *hasLocationImage;
    IBOutlet UIImageView *hasCommentsImage;
    IBOutlet UIImageView *isFavoriteImage;
    IBOutlet UIImageView *privacyImage;
    IBOutlet UILabel *usernameView;
    IBOutlet UILabel *timeagoView;
    IBOutlet UILabel *titleView;
    IBOutlet UIView *frameView;
    IBOutlet UIActivityIndicatorView *spinner;
}

+(CGFloat)cellHeightForPhoto:(StreamPhoto*)photo;

-(void) populateFromPhoto:(StreamPhoto*)photo;

@property (strong) StreamPhoto *photo;

@end
