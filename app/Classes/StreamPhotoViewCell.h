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
    IBOutlet UILabel *usernameView;
    IBOutlet UILabel *placeView;
    IBOutlet UILabel *timeagoView;
    IBOutlet UILabel *titleView;
    IBOutlet UILabel *descView;
    IBOutlet UILabel *visibilityView;
}

-(void) populateFromPhoto:(StreamPhoto*)photo;
-(void)loadImages;

@property (retain) StreamPhoto *photo;

@end
