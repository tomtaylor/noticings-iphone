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

@dynamic managedObjectModel, managedObjectContext, persistentStoreCoordinator;

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
	NSDictionary *defaults = @{@"defaultTags": @"",
                              @"filterInstagram": @NO, 
                              @"askedToFilterInstagram": @NO};
	[userDefaults registerDefaults:defaults];
	[userDefaults synchronize];

    [NSURLProtocol registerClass:[CacheURLProtocol class]];
    
    self.cacheManager = [[CacheManager alloc] init]; // first!
    self.contactsStreamManager = [[ContactsStreamManager alloc] init];
    self.uploadQueueManager = [[UploadQueueManager alloc] init];
    self.flickrCallManager = [[DeferredFlickrCallManager alloc] init];
	self.photoLocationManager = [[PhotoLocationManager alloc] init];
    
	self.queueTab = (self.tabBarController.tabBar.items)[0];
	int count = self.uploadQueueManager.queue.operationCount;
	
	if (count > 0) {
		self.queueTab.badgeValue = [NSString stringWithFormat:@"%u", count];
        application.applicationIconBadgeNumber = count;
	} else {
		self.queueTab.badgeValue = 0;
        application.applicationIconBadgeNumber = 0;
	}
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(queueDidChange:)
                                                 name:@"queueCount" 
                                               object:nil];	
    
    self.window.rootViewController = self.tabBarController;
    [self.window addSubview:[self.tabBarController view]];
	[self.window makeKeyAndVisible];
    
    DLog(@"Launch options: %@", launchOptions);
    
    // If there's no launch URL, then we haven't opened due to an auth callback.
    // If there is, we want to continue regardless, because we let the application:openURL: method below catch it.
    // We don't want to catch it here, because this is only called on launch, and won't call if the application is waking up after being backgrounded.
    NSURL *launchURL = launchOptions[UIApplicationLaunchOptionsURLKey];
    if (!launchURL && ![self isAuthenticated]) {
        DLog(@"App is not authenticated, so popping sign in modal.");
        [self showSigninView];
    }
    
    return YES;
}

-(void)showSigninView;
{
    if (self.tabBarController.modalViewController) {
        [self.tabBarController dismissModalViewControllerAnimated:NO];
    }

    if (!self.authViewController) {
        self.authViewController = [[FlickrAuthenticationViewController alloc] init];
    }
    
    [self.authViewController displaySignIn];
    [self.tabBarController presentModalViewController:self.authViewController animated:NO];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url 
  sourceApplication:(NSString *)sourceApplication 
         annotation:(id)annotation
{
    DLog(@"App launched with URL: %@", [url absoluteString]);
    [self showSigninView];
    [self.authViewController displaySpinner];
    [self.authViewController finalizeAuthWithUrl:url];
    
    // when we return, make sure the feed is set.
    [self.tabBarController setSelectedIndex:0];
    return YES;
}

- (void)queueDidChange:(NSNotification*)notification {
    NSNumber *size = notification.object;
    if (![size isKindOfClass:NSNumber.class]) {
        return;
    }
	[UIApplication sharedApplication].applicationIconBadgeNumber = size.intValue;
	if (size.intValue > 0) {
		self.queueTab.badgeValue = [NSString stringWithFormat:@"%u", size.intValue];
	} else {
		self.queueTab.badgeValue = nil;
	}
}

- (void)setDefaults {
	NSDictionary *defaults = @{@"lastKnownLatitude": @51.477811f,
                                @"lastKnownLongitude": @-0.001475f,
                                @"savedUploads": @[]};
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)applicationDidEnterBackground:(UIApplication *)application;
{
    // something caused us to be bakgrounded. incoming call, home button, etc.
    [[NoticingsAppDelegate delegate].contactsStreamManager resetFlickrContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application;
{
    if ([self isAuthenticated]) {
        // resume from background. Multitasking devices only.
        [[NoticingsAppDelegate delegate].contactsStreamManager maybeRefresh]; // the viewcontroller listens to this
        
        // if we're looking at a list of photos, reload it, in case the user defaults have changed.
        UINavigationController *nav = (UINavigationController*)(self.tabBarController.viewControllers)[0];
        StreamViewController *svc = (StreamViewController*)nav.visibleViewController;
        if ([svc isKindOfClass:StreamViewController.class]) {
            [svc.tableView reloadData];
            [svc.streamManager maybeRefresh];
        }
        
    } else {
        [self showSigninView];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

#pragma mark -
#pragma UITabBarControllerDelegate methods

// this feels odd, but it's the easiest way of doing something when a tab is selected without having to hack the tabbar
- (BOOL)tabBarController:(UITabBarController *)aTabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([viewController isEqual:self.dummyViewController]) {
        if (self.cameraController == nil) {
            CameraController *aCameraController = [[CameraController alloc] initWithBaseViewController:self.tabBarController];
            self.cameraController = aCameraController;
        }
        
        if ([self.cameraController cameraIsAvailable]) {
            [self.cameraController presentCamera];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Camera Not Available" message:@"You can upload photos in your Camera Roll from the More tab." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
        return NO;
    }
    return YES;
}
               
- (BOOL)isAuthenticated
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"oauth_token"] != nil;
}


#pragma mark Core Data

// http://wiresareobsolete.com/wordpress/2009/12/adding-core-data-existing-iphone-projects/
- (NSManagedObjectContext *) managedObjectContext {
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"noticings.sqlite"]];
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
        /*TODO Error for store creation should be handled in here*/
    }
    
    return persistentStoreCoordinator;
}

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

-(void)savePersistentObjects;
{
    NSManagedObjectContext *context = [NoticingsAppDelegate delegate].managedObjectContext;
    NSError *error = nil;
    [context save:&error];
    if (error) {
        DLog(@"error saving: %@", error);
        abort();
    }
}


@end

