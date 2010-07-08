//
//  FlickrAuthenticationViewController.h
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObjectiveFlickr.h"

@interface FlickrAuthenticationViewController : UIViewController <OFFlickrAPIRequestDelegate> {
	OFFlickrAPIContext *apiContext;
	OFFlickrAPIRequest *flickrRequest;
	
	IBOutlet UIView *signInView;
	IBOutlet UIView *spinnerView;
}

- (IBAction)signIn;
- (void)finalizeAuthWithUrl:(NSURL *)url;
- (void)displaySignIn;
- (void)displaySpinner;

@property (nonatomic, retain) IBOutlet UIView *signInView;
@property (nonatomic, retain) IBOutlet UIView *spinnerView;

@end
