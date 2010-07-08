//
//  NoticingsAppDelegate.h
//  Noticings
//
//  Created by Tom Taylor on 06/08/2009.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "FlickrAuthenticationViewController.h"
#import "UploadQueueManager.h"

@interface NoticingsAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
    UITabBarController *tabBarController;
	FlickrAuthenticationViewController *authViewController;
	UploadQueueManager *uploadQueueManager;
	UITabBarItem *queueTab;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;

@end

