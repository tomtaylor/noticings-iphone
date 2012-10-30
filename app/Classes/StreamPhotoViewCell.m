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

#define MAX_IMAGE_HEIGHT 320


-(void) populateFromPhoto:(StreamPhoto*)setphoto;
{
    //DLog(@"populateFromPhoto %@", setphoto);
    if (self.photo == setphoto) {
        return;
    }
    
    // need to watch for changes to photo object as updates come in.
    if (self.photo != nil) {
        [self.photo removeObserver:self forKeyPath:@"isfavorite"];
        [self.photo removeObserver:self forKeyPath:@"comments"];
        [self.photo removeObserver:self forKeyPath:@"needsFetch"];
    }
    self.photo = setphoto;
    
    [self updateView];
    [self loadImages];

    [self.photo addObserver:self forKeyPath:@"isfavorite" options:0 context:nil];
    [self.photo addObserver:self forKeyPath:@"comments" options:0 context:nil];
    [self.photo addObserver:self forKeyPath:@"needsFetch" options:0 context:nil];
}

-(void)loadImages;
{
    avatarView.image = [UIImage imageNamed:@"235-person"];
    photoView.image = [UIImage imageNamed:@"photos"];
    photoView.contentMode = UIViewContentModeCenter;

    StreamPhoto *originalPhoto = self.photo;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * data = [[NSData alloc] initWithContentsOfURL:self.photo.imageURL];
        UIImage * image = [[UIImage alloc] initWithData:data];
        if (image != nil) {
            dispatch_async( dispatch_get_main_queue(), ^{
                if (self.photo == originalPhoto) {
                    photoView.image = image;
                    
                    // make landscape images aspect fill and crop to frame, so we get perfect margins.
                    // or actually, images that are close enough to landscape that we'd get ugly margins.
                    if ([self.photo imageHeightForWidth:320] <= MAX_IMAGE_HEIGHT) {
                        photoView.contentMode = UIViewContentModeScaleAspectFill;
                    } else {
                        photoView.contentMode = UIViewContentModeScaleAspectFit;
                    }
                }
            });
        }
    });

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * data = [[NSData alloc] initWithContentsOfURL:self.photo.avatarURL];
        UIImage * image = [[UIImage alloc] initWithData:data];
        if (image != nil) {
            dispatch_async( dispatch_get_main_queue(), ^{
                if (self.photo == originalPhoto) {
                    avatarView.image = image;
                }
            });
        }
    });

}

#define ICON_STEP 3


-(void)updateView;
{
    titleView.text = self.photo.title;
    usernameView.text = self.photo.ownername;
    timeagoView.text = self.photo.ago;
    
    float left = privacyImage.frame.origin.x;
    
    if (self.photo.hasLocation) {
        hasLocationImage.hidden = NO;
        CGRect f = hasLocationImage.frame;
        left -= f.size.width + ICON_STEP;
        f.origin.x = left;
        hasLocationImage.frame = f;
    } else {
        hasLocationImage.hidden = YES;
    }
    
    if (self.photo.isfavorite.boolValue) {
        isFavoriteImage.hidden = NO;
        CGRect f = isFavoriteImage.frame;
        left -= f.size.width + ICON_STEP;
        f.origin.x = left;
        isFavoriteImage.frame = f;
    } else {
        isFavoriteImage.hidden = YES;
    }
    
    if (self.photo.comments.intValue > 0) {
        hasCommentsImage.hidden = NO;
        CGRect f = hasCommentsImage.frame;
        left -= f.size.width + ICON_STEP;
        f.origin.x = left;
        hasCommentsImage.frame = f;
    } else {
        hasCommentsImage.hidden = YES;
    }
    
    if (self.photo.needsFetch.boolValue) {
        spinner.hidden = NO;
        [spinner startAnimating];
        CGRect f = spinner.frame;
        left -= f.size.width + ICON_STEP;
        f.origin.x = left;
        spinner.frame = f;
    } else {
        spinner.hidden = YES;
        [spinner stopAnimating];
    }
    
    int vis = self.photo.visibility;
    if (vis == StreamPhotoVisibilityPrivate) {
        privacyImage.image = [UIImage imageNamed:@"visibility_red"];
    } else if (vis == StreamPhotoVisibilityLimited) {
        privacyImage.image = [UIImage imageNamed:@"visibility_yellow"];
    } else if (vis == StreamPhotoVisibilityPublic) {
        privacyImage.image = [UIImage imageNamed:@"visibility_green"];
    }

    // all the views in the nib have the right affinity to edges and know how to scale
    // themselves, so we just have to resize the outer frame and re-lay them out.
    CGRect frame = self.frame;
    frame.size.height = [StreamPhotoViewCell cellHeightForPhoto:self.photo];
    self.frame = frame;

    DLog(@"set needs display");
    [self setNeedsDisplay];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    StreamPhoto *photo = object;
    
    DLog(@"watched photo %@ changed (%@ %@ %@)", object, photo.isfavorite, photo.comments, photo.needsFetch);
    if (object == self.photo) {
        DLog(@"that's me!");
        // KVO isn't main-thread
        dispatch_async(dispatch_get_main_queue(),^{
            [self updateView];
        });
    }
}

+(CGFloat)cellHeightForPhoto:(StreamPhoto*)photo;
{
    // the desired height of the cell is the height of the photo plus the height of the controls.
    // all we need to do is get the outer frame right - everything else lays itself out properly.
    // In theory, we need to be _perfect_ here - too tall or wide and images won't have the right 
    // margins. In practice, this turns out to be hard (Why?) so I cheat be flipping the image view
    // to "aspect fill" for landscape images, so as long as we're within 1% here everything looks
    // fine.
    
    CGFloat controls = 80;

    // ideal image height, limited to a maximum so images don't make cells bigger than the window.
    CGFloat wantedImageHeight = MIN( [photo imageHeightForWidth:320], MAX_IMAGE_HEIGHT);
    
    return wantedImageHeight + controls;
}

-(void) gotLocation:(NSString*)location forPhoto:(StreamPhoto*)photo;
{
    // note that this cell can be re-used, so don't overwrite the wrong location.
    if ([photo.woeid isEqual:self.photo.woeid]) {
        //placeView.text = [@"⊙" stringByAppendingString:location];
    }
}


-(void)dealloc;
{
    if (self.photo != nil) {
        [self.photo removeObserver:self forKeyPath:@"isfavorite"];
        [self.photo removeObserver:self forKeyPath:@"comments"];
        [self.photo removeObserver:self forKeyPath:@"needsFetch"];
        self.photo = nil;
    }
}

@end
