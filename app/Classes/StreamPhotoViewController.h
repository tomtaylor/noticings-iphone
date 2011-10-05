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
#import "CacheManager.h"

@interface StreamPhotoViewController : UIViewController <UIWebViewDelegate, DeferredImageLoader> {
}

-(void)showPhoto:(StreamPhoto*)_photo;
-(void)updateHTML;

@property (retain) UIWebView *webView;

@property (retain) StreamPhoto* photo;
@property (retain) PhotoStreamManager *streamManager;
@property (retain) NSString *photoLocation;

@property (retain) NSArray *comments;
@property (assign) BOOL commentsError;

@end
