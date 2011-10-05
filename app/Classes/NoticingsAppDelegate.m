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
#import "ContactsStreamManager.h"
#import "CacheManager.h"
#import <ImageIO/ImageIO.h>
#import "StreamViewController.h"

#ifdef DEBUG
#import "TestFlight.h"
#import "APIKeys.h"
#endif

@implementation NoticingsAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize dummyViewController;
@synthesize cameraController;
@synthesize streamNavigationController;

BOOL gLogging = FALSE;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    #ifdef DEBUG
    [TestFlight takeOff:TESTFLIGHT_API_KEY];
    #endif
    
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaults = [NSDictionary dictionaryWithObject:@"" forKey:@"defaultTags"];
	[userDefaults registerDefaults:defaults];
	[userDefaults synchronize];
	
//	uploadQueueManager = [UploadQueueManager sharedUploadQueueManager];
//	[uploadQueueManager restoreQueuedUploads];

	queueTab = [tabBarController.tabBar.items objectAtIndex:0];
	int count = [[UploadQueueManager sharedUploadQueueManager].photoUploads count];
	
	if (count > 0) {
		queueTab.badgeValue = [NSString stringWithFormat:@"%u",	count];
	} else {
		queueTab.badgeValue = nil;
	}
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(queueDidChange) 
                                                 name:@"queueCount" 
                                               object:nil];	
    
    [[UploadQueueManager sharedUploadQueueManager] addObserver:self
                                                    forKeyPath:@"inProgress"
                                                       options:(NSKeyValueObservingOptionNew)
                                                       context:NULL];
    
    [window addSubview:[tabBarController view]];
	[window makeKeyAndVisible];
    
    DLog(@"Launch options: %@", launchOptions);
    
    // If there's no launch URL, then we haven't opened due to an auth callback.
    // If there is, we want to continue regardless, because we let the application:openURL: method below catch it.
    // We don't want to catch it here, because this is only called on launch, and won't call if the application is waking up after being backgrounded.
    NSURL *launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    if (!launchURL && ![self isAuthenticated]) {
        DLog(@"App is not authenticated, so popping sign in modal.");
        
        if (!authViewController) {
            authViewController = [[FlickrAuthenticationViewController alloc] init];
        }
        
        [authViewController displaySignIn];
        [tabBarController presentModalViewController:authViewController animated:NO];
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application 
            openURL:(NSURL *)url 
  sourceApplication:(NSString *)sourceApplication 
         annotation:(id)annotation
{
    DLog(@"App launched with URL: %@", [url absoluteString]);
    //[tabBarController dismissModalViewControllerAnimated:NO];
    
    if (tabBarController.modalViewController) {
        [tabBarController dismissModalViewControllerAnimated:NO];
    }
    
    if (!authViewController) {
        authViewController = [[FlickrAuthenticationViewController alloc] init];
    }
    
    [authViewController displaySpinner];
    [authViewController finalizeAuthWithUrl:url];
    [tabBarController presentModalViewController:authViewController animated:NO];
    
    // when we return, make sure the feed is set.
    [tabBarController setSelectedIndex:0];
    return YES;
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

- (void)applicationDidEnterBackground:(UIApplication *)application;
{
    // something caused us to be bakgrounded. incoming call, home button, etc.
    [[CacheManager sharedCacheManager] flushMemoryCache];
    [[ContactsStreamManager sharedContactsStreamManager] resetFlickrContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application;
{
    // resume from background. Multitasking devices only.
    [[ContactsStreamManager sharedContactsStreamManager] maybeRefresh]; // the viewcontroller listens to this
}

- (void)applicationWillTerminate:(UIApplication *)application {
	//[uploadQueueManager saveQueuedUploads];
	[UIApplication sharedApplication].applicationIconBadgeNumber = [uploadQueueManager.photoUploads count];
}

#pragma mark -
#pragma UITabBarControllerDelegate methods

// this feels odd, but it's the easiest way of doing something when a tab is selected without having to hack the tabbar
- (BOOL)tabBarController:(UITabBarController *)aTabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([viewController isEqual:dummyViewController]) {
        if (self.cameraController == nil) {
            CameraController *aCameraController = [[CameraController alloc] initWithBaseViewController:self.tabBarController];
            self.cameraController = aCameraController;
            [aCameraController release];
        }
        
        if ([self.cameraController cameraIsAvailable]) {
            [self.cameraController presentCamera];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Camera Not Available" message:@"You can upload photos in your Camera Roll from the More tab." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
            [alertView release];
        }
        return NO;
    }
    return YES;
}
               
- (BOOL)isAuthenticated
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"] != nil;
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [authViewController release];
	[tabBarController release];
    [cameraController release];
	[window release];
	[super dealloc];
}

@end

