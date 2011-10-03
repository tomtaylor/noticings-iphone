//
//  StreamPhotoViewController.h
//  Noticings
//
//  Created by Tom Insam on 30/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "StreamPhoto.h"
#import "RemoteImageView.h"
#import "PhotoStreamManager.h"

@interface StreamPhotoViewController : UIViewController {
    IBOutlet RemoteImageView *avatarView;
    IBOutlet RemoteImageView *photoView;
    IBOutlet RemoteImageView *mapView;
    IBOutlet UILabel *usernameView;
    IBOutlet UILabel *placeView;
    IBOutlet UILabel *timeagoView;
    IBOutlet UILabel *titleView;
    IBOutlet UIWebView *descView;
    IBOutlet UILabel *visibilityView;
    IBOutlet UIView *theView;
    IBOutlet UIGestureRecognizer *tapGestureRecognizer;
}

-(void)showPhoto:(StreamPhoto*)_photo;
-(void)updateHTML;

@property (retain) StreamPhoto* photo;
@property (retain) PhotoStreamManager *streamManager;

@property (retain) NSString *photoLocation;

@end
