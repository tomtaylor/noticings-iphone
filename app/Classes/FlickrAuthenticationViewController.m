//
//  FlickrAuthenticationViewController.m
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FlickrAuthenticationViewController.h"
//#import "UploadQueueManager.h"
#import "ContactsStreamManager.h"
#import "APIKeys.h"

@implementation FlickrAuthenticationViewController

@synthesize signInView;
@synthesize spinnerView;

- (id) init
{
	self = [super init];
	if (self != nil) {
		apiContext = [[OFFlickrAPIContext alloc] initWithAPIKey:FLICKR_API_KEY sharedSecret:FLICKR_API_SECRET];
		[apiContext setAuthEndpoint:@"http://m.flickr.com/services/auth/"];
	}
	return self;
}

- (void)displaySignIn {
	NSLog(@"displaying signin");
	[self.spinnerView removeFromSuperview];
	[self.view addSubview:self.signInView];
}

- (void)displaySpinner {
	NSLog(@"displaying spinner");
	[self.signInView removeFromSuperview];
	[self.view addSubview:self.spinnerView];
}


- (IBAction)signIn {
	NSURL *authUrl = [apiContext loginURLFromFrobDictionary:nil requestedPermission:OFFlickrWritePermission];
	[[UIApplication sharedApplication] openURL:authUrl];
}

- (OFFlickrAPIRequest *)flickrRequest
{
	if (!flickrRequest) {
		flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:apiContext];
		flickrRequest.delegate = self;
	}
	
	return flickrRequest;
}

- (void)finalizeAuthWithUrl:(NSURL *)url {
	NSString *frob = [[url query] substringFromIndex:5];	
	[[self flickrRequest] callAPIMethodWithGET:@"flickr.auth.getToken" arguments:[NSDictionary dictionaryWithObjectsAndKeys:frob, @"frob", nil]];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest 
 didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
	NSString *authToken = [[inResponseDictionary valueForKeyPath:@"auth.token"] textContent];
	[[NSUserDefaults standardUserDefaults] setObject:authToken forKey:@"authToken"];
	
	NSString *userName = [inResponseDictionary valueForKeyPath:@"auth.user.username"];
	[[NSUserDefaults standardUserDefaults] setObject:userName forKey:@"userName"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
    
    [[ContactsStreamManager sharedContactsStreamManager] refresh];
	
	[[[[UIAlertView alloc] initWithTitle:@"Welcome to Noticings" message:@"You've been signed in." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
	
	[self dismissModalViewControllerAnimated:YES];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
	[[[[UIAlertView alloc] initWithTitle:@"Flickr Authentication Failed" message:@"There was a problem signing you into Flickr. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
    [self displaySignIn];
}

- (void) dealloc
{
    // ensure if we dealloc with a request inflight that we don't crash on return.
    if (flickrRequest) {
        flickrRequest.delegate = nil;
    }
	[flickrRequest release];
	[apiContext release];
	[super dealloc];
}


@end
