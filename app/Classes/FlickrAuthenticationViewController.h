//
//  FlickrAuthenticationViewController.h
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlickrAuthenticationViewController : UIViewController

- (IBAction)signIn;
- (void)finalizeAuthWithUrl:(NSURL *)url;
- (void)displaySignIn;
- (void)displaySpinner;

@property (nonatomic, retain) IBOutlet UIView *signInView;
@property (nonatomic, retain) IBOutlet UIView *spinnerView;

@end
