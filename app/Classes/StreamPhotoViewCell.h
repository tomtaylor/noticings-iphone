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
    UILabel *visibilityView;
}

-(id)initWithBounds:(CGRect)bounds;
-(void) populateFromPhoto:(StreamPhoto*)photo;
+(CGFloat) cellHeightForPhoto:(StreamPhoto*)photo;
-(UILabel*) addLabelWithFrame:(CGRect)frame fontSize:(int)size bold:(BOOL)bold color:(UIColor*)color;


#define PADDING_SIZE 7.0f
#define AVATAR_SIZE 40.0f
#define TIMEBOX_SIZE 70.0f
#define IMAGE_WIDTH (320.0f - PADDING_SIZE * 2)
#define HEADER_FONT_SIZE 14
#define FONT_SIZE 14


@end
