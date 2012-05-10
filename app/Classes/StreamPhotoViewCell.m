//
//  StreamPhotoViewCell.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamPhotoViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "NoticingsAppDelegate.h"

@implementation StreamPhotoViewCell
@synthesize photo;

#define MAX_IMAGE_HEIGHT 360


-(void) populateFromPhoto:(StreamPhoto*)_photo;
{
    // drop shadow on the white photo background
//    frameView.layer.shadowOffset = CGSizeMake(0,2);
//    frameView.layer.shadowColor = [[UIColor blackColor] CGColor];
//    frameView.layer.shadowRadius = 5.0f;
//    frameView.layer.shadowOpacity = 0.6f;
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.6f alpha:1.0f];

    self.photo = _photo;

    titleView.text = photo.title;
    usernameView.text = photo.ownername;

    // gfx are for losers. I like unicode.
    timeagoView.text = [@"⌚" stringByAppendingString:photo.ago];

    hasLocationImage.hidden = !photo.hasLocation;

    int vis = photo.visibility;
    if (vis == StreamPhotoVisibilityPrivate) {
        privacyImage.image = [UIImage imageNamed:@"visibility_red.png"];
    } else if (vis == StreamPhotoVisibilityLimited) {
        privacyImage.image = [UIImage imageNamed:@"visibility_yellow.png"];
    } else if (vis == StreamPhotoVisibilityPublic) {
        privacyImage.image = [UIImage imageNamed:@"visibility_green.png"];
    }
    
    // make landscape images aspect fill and crop to frame, so we get perfect margins.
    // or actually, images that are close enough to landscape that we'd get ugly margins.
    if ([photo imageHeightForWidth:320] <= MAX_IMAGE_HEIGHT * 1.0) {
        photoView.contentMode = UIViewContentModeScaleAspectFill;
    } else {
        photoView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    // all the views in the nib have the right affinity to edges and know how to scale
    // themselves, so we just have to resize the outer frame and re-lay them out.
    CGRect frame = self.frame;
    frame.size.height = [StreamPhotoViewCell cellHeightForPhoto:photo];
    self.frame = frame;
    
}

+(CGFloat)cellHeightForPhoto:(StreamPhoto*)photo;
{
    // the desired height of the cell is the height of the photo plus the height of the controls.
    // all we need to do is get the outer frame right - everything else lays itself out properly.
    // In theory, we need to be _perfect_ here - too tall or wide and images won't have the right 
    // margins. In practice, this turns out to be hard (Why?) so I cheat be flipping the image view
    // to "aspect fill" for landscape images, so as long as we're within 1% here everything looks
    // fine.
    
    CGFloat nativeCellHeight = 370; // copy from table cell nib if you change it.
    CGFloat roomForControls = nativeCellHeight - 310; // image in nib is 310 high. Everything else in cell must therefore be..

    // ideal image height, limited to a maximum so images don't make cells bigger than the window.
    CGFloat wantedImageHeight = MIN( [photo imageHeightForWidth:320], MAX_IMAGE_HEIGHT);
    
    return wantedImageHeight + roomForControls;
}


-(void)loadImages;
{
    CacheManager *manager = [NoticingsAppDelegate delegate].cacheManager;

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
        //placeView.text = [@"⊙" stringByAppendingString:location];
    }
}


- (void)dealloc {
    self.photo = nil;
    [super dealloc];
}


@end
