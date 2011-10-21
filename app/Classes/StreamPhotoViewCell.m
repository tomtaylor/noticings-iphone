//
//  StreamPhotoViewCell.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamPhotoViewCell.h"

@implementation StreamPhotoViewCell
@synthesize photo;

-(void) populateFromPhoto:(StreamPhoto*)_photo;
{
    self.photo = _photo;

    titleView.text = photo.title;
    usernameView.text = photo.ownername;

    // gfx are for losers. I like unicode.
    timeagoView.text = [@"⌚" stringByAppendingString:photo.ago];

    
    // not showing desc so the cell is a more predictable size.
    descView.text = @"";
    //descView.text = photo.description;

    if (photo.hasLocation) {
        NSString *cached = [[PhotoLocationManager sharedPhotoLocationManager] cachedLocationForPhoto:photo];
        if (cached) {
            placeView.text = cached;
        } else {
            placeView.text = photo.placename;
            [[PhotoLocationManager sharedPhotoLocationManager] getLocationForPhoto:photo andTell:self];
        }

    } else {
        placeView.text = @"";
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
    
    // not showing desc so the cell is a more predictable size.
    //frame.origin.y = y + frame.size.height + PADDING_SIZE;
    //descView.frame = frame;
    //[descView sizeToFit];
    //frame = self.frame;
    //frame.size.height = descView.frame.origin.y + descView.frame.size.height + PADDING_SIZE;

    self.frame = frame;
}


-(void)loadImages;
{
    CacheManager *manager = [CacheManager sharedCacheManager];

    UIImage *cached = [manager cachedImageForURL:photo.imageURL];
    if (cached) {
        photoView.image = cached;
    } else {
        photoView.image = nil; // TODO - loading spinner or something.
        [manager fetchImageForURL:photo.imageURL andNotify:self];
    }
    
    cached = [manager cachedImageForURL:photo.avatarURL];
    if (cached) {
        avatarView.image = cached;
    } else {
        avatarView.image = nil; // TODO - loading spinner or something.
        [manager fetchImageForURL:photo.avatarURL andNotify:self];
    }
}


-(void) loadedImage:(UIImage*)image forURL:(NSURL*)url cached:(BOOL)cached;
{
    if ([url isEqual:self.photo.imageURL]) {
        photoView.image = image;
    }
    if ([url isEqual:photo.avatarURL]) {
        avatarView.image = image;
    }
}


-(void) gotLocation:(NSString*)location forPhoto:(StreamPhoto*)_photo;
{
    // note that this cell can be re-used, so don't overwrite the wrong location.
    if ([_photo.woeid isEqual:self.photo.woeid]) {
        placeView.text = location;
    }
}


- (void)dealloc {
    self.photo = nil;
    [super dealloc];
}


@end
