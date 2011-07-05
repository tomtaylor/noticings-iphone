//
//  NoticingsAppDelegate.m
//  Noticings
//
//  Created by Tom Taylor on 06/08/2009.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "NoticingsAppDelegate.h"
#import "FlickrAuthenticationViewController.h"
#import "UploadQueueManager.h"

@implementation NoticingsAppDelegate

@synthesize window;
@synthesize tabBarController;

BOOL gLogging = FALSE;

#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaults = [NSDictionary dictionaryWithObject:@"noticings " forKey:@"defaultTags"];
	[userDefaults registerDefaults:defaults];
	[userDefaults synchronize];
	
	uploadQueueManager = [UploadQueueManager sharedUploadQueueManager];
	[uploadQueueManager restoreQueuedUploads];

	queueTab = [tabBarController.tabBar.items objectAtIndex:2];
	int count = [[UploadQueueManager sharedUploadQueueManager].photoUploads count];
	
	if (count > 0) {
		queueTab.badgeValue = [NSString stringWithFormat:@"%u",	count];
	} else {
		queueTab.badgeValue = nil;
	}
	
	authViewController = [[FlickrAuthenticationViewController alloc] init];
	
	[window addSubview:[tabBarController view]];
	[window makeKeyAndVisible];
	
	// Apple trick: Do this so after we got a chance to let application:handleOpenURL: run before our next stage of init...
	[self performSelector:@selector(_applicationDidFinishLaunchingContinued) withObject:nil afterDelay:0.0];
}

- (void)_applicationDidFinishLaunchingContinued
{
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"] == nil && authViewController.parentViewController == nil) {
		[authViewController displaySignIn];
		[tabBarController presentModalViewController:authViewController animated:YES];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(queueDidChange) 
												 name:@"queueCount" 
											   object:nil];	
	
	[[UploadQueueManager sharedUploadQueueManager] addObserver:self
													forKeyPath:@"inProgress"
													   options:(NSKeyValueObservingOptionNew)
													   context:NULL];
}

- (void)queueDidChange {
	int count = [[UploadQueueManager sharedUploadQueueManager].photoUploads count];
	[UIApplication sharedApplication].applicationIconBadgeNumber = count;
	
	if (count > 0) {
		queueTab.badgeValue = [NSString stringWithFormat:@"%u",	count];
	} else {
		queueTab.badgeValue = nil;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = [UploadQueueManager sharedUploadQueueManager].inProgress;
}


- (void)setDefaults {
	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:51.477811], @"lastKnownLatitude",
							  [NSNumber numberWithFloat:-0.001475], @"lastKnownLongitude",
							  [NSArray array], @"savedUploads",
							  nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if (!url) {  return NO; }
	[authViewController displaySpinner];
	[authViewController finalizeAuthWithUrl:url];
	[tabBarController presentModalViewController:authViewController animated:NO];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[uploadQueueManager saveQueuedUploads];
	[UIApplication sharedApplication].applicationIconBadgeNumber = [uploadQueueManager.photoUploads count];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[tabBarController release];
	[window release];
	[super dealloc];
}


@end

