//
//  StreamPhotoViewCell.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamPhoto.h"

@interface StreamPhotoViewCell : UITableViewCell {
    UIImageView *avatarView;
    UITextView *usernameView;
    UIImageView *imageView;
}

-(void) populateFromPhoto:(StreamPhoto*)photo;

@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIImageView *avatarView;
@property (nonatomic, retain) UITextView *usernameView;

@end
