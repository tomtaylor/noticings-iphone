//
//  StreamPhotoViewCell.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamPhoto.h"
#import "RemoteImageView.h"

@interface StreamPhotoViewCell : UITableViewCell {
    RemoteImageView *avatarView;
    RemoteImageView *photoView;
    UILabel *usernameView;
    UILabel *placeView;
    UILabel *timeagoView;
    UILabel *titleView;
    UILabel *descView;
}

-(id)initWithBounds:(CGRect)bounds;
-(void) populateFromPhoto:(StreamPhoto*)photo;
+(CGFloat) cellHeightForPhoto:(StreamPhoto*)photo;

@property (nonatomic, retain) RemoteImageView *photoView;
@property (nonatomic, retain) RemoteImageView *avatarView;
@property (nonatomic, retain) UILabel *usernameView;
@property (nonatomic, retain) UILabel *placeView;
@property (nonatomic, retain) UILabel *timeagoView;
@property (nonatomic, retain) UILabel *titleView;
@property (nonatomic, retain) UILabel *descView;

// these numbers arrived at by copying instagram. :-)
#define PADDING_SIZE 7.0f
#define AVATAR_SIZE 30.0f
#define TIMEBOX_SIZE 70.0f
#define IMAGE_SIZE (320.0f - PADDING_SIZE * 2)

@end
