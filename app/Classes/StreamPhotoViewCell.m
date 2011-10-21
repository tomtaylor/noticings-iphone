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

#define MAX_IMAGE_HEIGHT 280

-(void) populateFromPhoto:(StreamPhoto*)_photo;
{
    self.photo = _photo;

    titleView.text = photo.title;
    usernameView.text = photo.ownername;

    // gfx are for losers. I like unicode.
    timeagoView.text = [@"⌚" stringByAppendingString:photo.ago];

    
    // not showing desc so the cell is a more predictable size.
    //descView.text = @"";
    //descView.text = photo.description;

    hasLocationImage.hidden = !photo.hasLocation;

//    if (photo.hasLocation) {
//        NSString *cached = [[PhotoLocationManager sharedPhotoLocationManager] cachedLocationForPhoto:photo];
//        if (cached) {
//            placeView.text = [@"⊙" stringByAppendingString:cached];
//        } else {
//            placeView.text = [@"⊙" stringByAppendingString:photo.placename];
//            [[PhotoLocationManager sharedPhotoLocationManager] getLocationForPhoto:photo andTell:self];
//        }
//
//    } else {
//        placeView.text = @"No location";
//    }

    int vis = photo.visibility;
    if (vis == StreamPhotoVisibilityPrivate) {
//        visibilityView.text = @"private";
//        visibilityView.textColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:1];
        privacyImage.backgroundColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:1];
    } else if (vis == StreamPhotoVisibilityLimited) {
//        visibilityView.text = @"limited";
//        visibilityView.textColor = [UIColor colorWithRed:0.7 green:0.7 blue:0 alpha:1];
        privacyImage.backgroundColor = [UIColor colorWithRed:0.7 green:0.7 blue:0 alpha:1];
    } else if (vis == StreamPhotoVisibilityPublic) {
//        visibilityView.text = @"public";
//        visibilityView.textColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
        privacyImage.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
    }
    
    // make landscape images aspect fill and crop to frame, so we get perfect margins.
    // or actually, images that are close enough to landscape that we'd get ugly margins.
    if ([photo imageHeightForWidth:320] <= MAX_IMAGE_HEIGHT * 1.2) {
        NSLog(@"photo %@ is landscape", photo);
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
    
    CGFloat nativeCellHeight = 377; // copy from table cell nib if you change it.
    CGFloat roomForControls = nativeCellHeight - 310; // image in nib is 310 high. Everything else in cell must therefore be..

    // ideal image height, limited to a maximum so images don't make cells bigger than the window.
    CGFloat wantedImageHeight = MIN( [photo imageHeightForWidth:320], MAX_IMAGE_HEIGHT);
    
    return wantedImageHeight + roomForControls;
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
        //placeView.text = [@"⊙" stringByAppendingString:location];
    }
}


- (void)dealloc {
    self.photo = nil;
    [super dealloc];
}


@end
