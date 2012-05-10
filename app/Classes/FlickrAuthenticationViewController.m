//
//  FlickrAuthenticationViewController.m
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FlickrAuthenticationViewController.h"
#import "ContactsStreamManager.h"
#import "APIKeys.h"
#import "GCOAuth.h"
#import "NSString+URI.h"

@interface NSString (Noticings)
-(NSDictionary*)dictionaryByParsingAsQueryParameters;
@end

@implementation NSString (Noticings)

-(NSDictionary*)dictionaryByParsingAsQueryParameters;
{
    NSMutableDictionary *parsed = [NSMutableDictionary dictionary];
    [[self componentsSeparatedByString:@"&"] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        NSArray *bits = [obj componentsSeparatedByString:@"="];
        if (bits.count == 2) {
            NSString *k = [[bits objectAtIndex:0] stringByDecodingFromURI];
            NSString *v = [[bits objectAtIndex:1] stringByDecodingFromURI];
            [parsed setValue:v forKey:k];
        }
    }];
    return [NSDictionary dictionaryWithDictionary:parsed];
}

@end

@implementation FlickrAuthenticationViewController

@synthesize signInView;
@synthesize spinnerView;

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
    [self displaySpinner];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"noticings://", @"callback",
                                nil];
        NSURLRequest *req = [GCOAuth URLRequestForPath:@"/services/oauth/request_token"
                                         GETParameters:params
                                                scheme:@"http"
                                                  host:@"www.flickr.com"
                                           consumerKey:FLICKR_API_KEY
                                        consumerSecret:FLICKR_API_SECRET
                                           accessToken:nil
                                           tokenSecret:nil];

        NSHTTPURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
        NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (response.statusCode != 200) {
            dispatch_async(dispatch_get_main_queue(),^{
                [[[[UIAlertView alloc] initWithTitle:@"Noticings"
                                             message:@"There was a problem talking to Flickr. Try again later."
                                            delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil] autorelease] show];
                return;
            });
        }
            
        NSDictionary *parsed = [body dictionaryByParsingAsQueryParameters];
        [body release];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:[parsed objectForKey:@"oauth_token"] forKey:@"request_token"];
        [defaults setValue:[parsed objectForKey:@"oauth_token_secret"] forKey:@"request_secret"];
        [defaults synchronize];
        
        NSString *redirect = [NSString stringWithFormat:@"http://www.flickr.com/services/oauth/authorize?oauth_token=%@", [parsed objectForKey:@"oauth_token"]];

        dispatch_async(dispatch_get_main_queue(),^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:redirect]];
        });
    });

	
}

- (void)finalizeAuthWithUrl:(NSURL *)url {
    NSString *queryString = [[url.absoluteString componentsSeparatedByString:@"?"] objectAtIndex:1];
    NSDictionary *urlParams = [queryString dictionaryByParsingAsQueryParameters];
    NSLog(@"incoming parsms are %@", urlParams);

    [self displaySpinner];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                [urlParams objectForKey:@"oauth_verifier"], @"oauth_verifier",
                                nil];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSURLRequest *req = [GCOAuth URLRequestForPath:@"/services/oauth/access_token"
                                         GETParameters:params
                                                scheme:@"http"
                                                  host:@"www.flickr.com"
                                           consumerKey:FLICKR_API_KEY
                                        consumerSecret:FLICKR_API_SECRET
                                           accessToken:[defaults valueForKey:@"request_token"]
                                           tokenSecret:[defaults valueForKey:@"request_secret"]];
        
        NSHTTPURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
        NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (response.statusCode != 200) {
            dispatch_async(dispatch_get_main_queue(),^{
                [[[[UIAlertView alloc] initWithTitle:@"Noticings"
                                             message:@"There was a problem talking to Flickr. Try again later."
                                            delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil] autorelease] show];
                return;
            });
        }
        
        NSDictionary *parsed = [body dictionaryByParsingAsQueryParameters];
        [body release];
        
        [defaults setValue:[parsed objectForKey:@"oauth_token"] forKey:@"oauth_token"];
        [defaults setValue:[parsed objectForKey:@"oauth_token_secret"] forKey:@"oauth_secret"];
        [defaults setValue:[parsed objectForKey:@"username"] forKey:@"userName"];
        [defaults setValue:[parsed objectForKey:@"fullname"] forKey:@"fullName"];
        [defaults setValue:[parsed objectForKey:@"user_nsid"] forKey:@"nsid"];
        [defaults synchronize];

        dispatch_async(dispatch_get_main_queue(),^{
            [self dismissModalViewControllerAnimated:YES];
        });
        
    });
}

@end
