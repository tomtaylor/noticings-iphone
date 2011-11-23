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

@interface StreamPhotoViewCell : UITableViewCell <DeferredImageLoader, LocationDelegate> {
    
    IBOutlet UIImageView *avatarView;
    IBOutlet UIImageView *photoView;
    IBOutlet UIImageView *hasLocationImage;
    IBOutlet UIImageView *privacyImage;
    IBOutlet UILabel *usernameView;
    IBOutlet UILabel *timeagoView;
    IBOutlet UILabel *titleView;

    IBOutlet UIView *frameView;
}

+(CGFloat)cellHeightForPhoto:(StreamPhoto*)photo;

-(void) populateFromPhoto:(StreamPhoto*)photo;
-(void)loadImages;

@property (retain) StreamPhoto *photo;

@end
