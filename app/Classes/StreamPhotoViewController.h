//
//  StreamPhotoViewController.h
//  Noticings
//
//  Created by Tom Insam on 30/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import <UIKit/UIKit.h>

#import "StreamPhoto.h"
#import "PhotoStreamManager.h"
#import "CacheManager.h"
#import "PhotoLocationManager.h"

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface StreamPhotoViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, LocationDelegate> {
    int sendMailIndex;
    int sendTweetIndex;
    int saveRollIndex;
}

-(id)initWithPhoto:(StreamPhoto*)photo streamManager:(PhotoStreamManager*)streamManager;
-(void)updateHTML;

@property (strong) UIWebView *webView;

@property (strong) StreamPhoto* photo;
@property (strong) PhotoStreamManager *streamManager;
@property (strong) NSString *photoLocation;

@property (strong) NSArray *comments;
@property (assign) BOOL commentsError;

@end
