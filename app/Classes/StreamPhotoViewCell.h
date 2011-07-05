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
    UITextView *usernameView;
    UITextView *placeView;
    UITextView *timeagoView;
}

-(id)initWithBounds:(CGRect)bounds;
-(void) populateFromPhoto:(StreamPhoto*)photo;

@property (nonatomic, retain) RemoteImageView *photoView;
@property (nonatomic, retain) RemoteImageView *avatarView;
@property (nonatomic, retain) UITextView *usernameView;
@property (nonatomic, retain) UITextView *placeView;
@property (nonatomic, retain) UITextView *timeagoView;

@end
