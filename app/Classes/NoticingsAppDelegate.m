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
#import "CacheURLProtocol.h"

#ifdef ADHOC
#import "TestFlight.h"
#import "APIKeys.h"
#endif

@implementation NoticingsAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize dummyViewController;
@synthesize cameraController;
@synthesize streamNavigationController;
@synthesize contactsStreamManager = _contactsStreamManager;
@synthesize cacheManager = _cacheManager;
@synthesize flickrCallManager = _flickrCallManager;
@synthesize uploadQueueManager = _uploadQueueManager;
@synthesize photoLocationManager = _photoLocationManager;

BOOL gLogging = FALSE;

#pragma mark -
#pragma mark Application lifecycle

+(NoticingsAppDelegate*)delegate;
{
    return (NoticingsAppDelegate*)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef ADHOC
    [TestFlight takeOff:TESTFLIGHT_API_KEY];
#endif
    
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"", @"defaultTags",
                              [NSNumber numberWithBool:NO], @"filterInstagram", 
                              [NSNumber numberWithBool:NO], @"askedToFilterInstagram", 
                              nil];
	[userDefaults registerDefaults:defaults];
	[userDefaults synchronize];

    [NSURLProtocol registerClass:[CacheURLProtocol class]];
    
    self.contactsStreamManager = [[[ContactsStreamManager alloc] init] autorelease];
    self.cacheManager = [[[CacheManager alloc] init] autorelease];
    self.uploadQueueManager = [[[UploadQueueManager alloc] init] autorelease];
    self.flickrCallManager = [[[DeferredFlickrCallManager alloc] init] autorelease];
	self.photoLocationManager = [[[PhotoLocationManager alloc] init] autorelease];
    
	queueTab = [tabBarController.tabBar.items objectAtIndex:0];
	int count = self.uploadQueueManager.queue.operationCount;
	
	if (count > 0) {
		queueTab.badgeValue = [NSString stringWithFormat:@"%u",	count];
        application.applicationIconBadgeNumber = count;
	} else {
		queueTab.badgeValue = 0;
        application.applicationIconBadgeNumber = 0;
	}
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(queueDidChange) 
                                                 name:@"queueCount" 
                                               object:nil];	
    
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
	int count = [NoticingsAppDelegate delegate].uploadQueueManager.queue.operationCount;
	[UIApplication sharedApplication].applicationIconBadgeNumber = count;
	if (count > 0) {
		queueTab.badgeValue = [NSString stringWithFormat:@"%u",	count];
	} else {
		queueTab.badgeValue = nil;
	}
}

- (void)setDefaults {
	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithFloat:51.477811], @"lastKnownLatitude",
                                [NSNumber numberWithFloat:-0.001475], @"lastKnownLongitude",
                                [NSArray array], @"savedUploads",
                                nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)applicationDidEnterBackground:(UIApplication *)application;
{
    // something caused us to be bakgrounded. incoming call, home button, etc.
    [[NoticingsAppDelegate delegate].contactsStreamManager resetFlickrContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application;
{
    // resume from background. Multitasking devices only.
    [[NoticingsAppDelegate delegate].contactsStreamManager maybeRefresh]; // the viewcontroller listens to this
    
    // if we're looking at a list of photos, reload it, in case the user defaults have changed.
    UINavigationController *nav = (UINavigationController*)[self.tabBarController.viewControllers objectAtIndex:0];
    if (nav.visibleViewController.class == StreamViewController.class) {
        [((StreamViewController*)nav.visibleViewController).tableView reloadData];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
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
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"oauth_token"] != nil;
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

