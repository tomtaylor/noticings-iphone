//
//  StreamPhotoViewController.h
//  Noticings
//
//  Created by Tom Insam on 30/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "StreamPhoto.h"
#import "PhotoStreamManager.h"
#import "CacheManager.h"
#import "PhotoLocationManager.h"

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface StreamPhotoViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, DeferredImageLoader, LocationDelegate> {
    BOOL firstRender;
    
    int sendMailIndex;
    int sendTweetIndex;
    int saveRollIndex;
}

-(id)initWithPhoto:(StreamPhoto*)photo streamManager:(PhotoStreamManager*)streamManager;
-(void)updateHTML;

@property (retain) UIWebView *webView;

@property (retain) StreamPhoto* photo;
@property (retain) PhotoStreamManager *streamManager;
@property (retain) NSString *photoLocation;

@property (retain) NSArray *comments;
@property (assign) BOOL commentsError;

@end
