//
//  StreamPhotoViewCell.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamPhotoViewCell.h"

#import "APIKeys.h"
#import "ObjectiveFlickr.h"

@implementation StreamPhotoViewCell

-(void) populateFromPhoto:(StreamPhoto*)photo;
{
    usernameView.text = photo.ownername;
    // gfx are for losers. I like unicode.
    timeagoView.text = [@"⌚" stringByAppendingString:photo.ago];
    titleView.text = photo.title;
    descView.text = photo.description;
    if (photo.hasLocation) {
        placeView.text = photo.placename;
    }

    int vis = photo.visibility;
    if (vis == StreamPhotoVisibilityPrivate) {
        visibilityView.text = @"private";
        visibilityView.textColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:1];
    } else if (vis == StreamPhotoVisibilityLimited) {
        visibilityView.text = @"limited";
        visibilityView.textColor = [UIColor colorWithRed:0.7 green:0.7 blue:0 alpha:1];
    } else if (vis == StreamPhotoVisibilityPublic) {
        visibilityView.text = @"public";
        visibilityView.textColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
    }

    [photoView loadURL:photo.imageURL];
    [avatarView loadURL:photo.avatarURL];
    
    // resize image frame to have the right aspect.
    // (but if it's taller than square it won't fit in the view.)
    CGRect frame = photoView.frame;
    CGFloat height = MIN( [photo imageHeightForWidth:frame.size.width], 260);
    frame.size.height = height;
    photoView.frame = frame;

    CGFloat y = photoView.frame.origin.y + photoView.frame.size.height + PADDING_SIZE;
    frame = titleView.frame;
    frame.origin.y = y;
    titleView.frame = frame;
    
    frame.origin.y = y + frame.size.height + PADDING_SIZE;
    descView.frame = frame;

    [descView sizeToFit];
    
    frame = self.frame;
    frame.size.height = descView.frame.origin.y + descView.frame.size.height + PADDING_SIZE;
    self.frame = frame;
}

- (void)dealloc {
    [super dealloc];
}


@end
