//
//  StreamPhotoViewController.m
//  Noticings
//
//  Created by Tom Insam on 30/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import "Twitter/Twitter.h"
#import "GRMustache.h"
#import "NoticingsAppDelegate.h"

#import "StreamPhotoViewController.h"
#import "StreamPhotoViewCell.h"
#import "UserStreamManager.h"
#import "ImageViewController.h"
#import "MapViewController.h"
#import "StreamViewController.h"
#import "PhotoLocationManager.h"
#import "DeferredFlickrCallManager.h"
#import "TagStreamManager.h"
#import "AddCommentViewController.h"

#import "NSString+URI.h"
#import "UIColor+Hex.h"

@implementation StreamPhotoViewController

// global template object cache
GRMustacheTemplate *template;

-(id)initWithPhoto:(StreamPhoto*)photo streamManager:(PhotoStreamManager*)streamManager;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.photo = photo;
        self.streamManager = streamManager;
        self.title = @""; // self.photo.title;
    }
    return self;
}

-(void)loadView;
{
    [super loadView];
}

-(void)viewDidLoad;
{
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.comments = nil;
    self.commentsError = NO;
    self.view.autoresizesSubviews = YES;
    [self.view addSubview:self.webView];

    UIBarButtonItem *externalItem = [[UIBarButtonItem alloc] 
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                     target:self
                                     action:@selector(externalButton)];
    
    self.navigationItem.rightBarButtonItem = externalItem;


    // hide the shadows
    for (UIView* shadowView in [[self.webView subviews][0] subviews]) {
        [shadowView setHidden:YES];
    }
    [[[[self.webView subviews][0] subviews] lastObject] setHidden:NO];
    self.view.backgroundColor = [UIColor colorWithCSS:@"#404040"];
    self.webView.backgroundColor = self.view.backgroundColor;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] 
                                   initWithTitle: @"Photo" 
                                   style: UIBarButtonItemStyleBordered
                                   target: nil action: nil];
    
    [self.navigationItem setBackBarButtonItem: backButton];

}

-(void)externalButton;
{
    UIActionSheet *popupQuery = [[UIActionSheet alloc]
                                 initWithTitle:nil
                                 delegate:self
                                 cancelButtonTitle:nil
                                 destructiveButtonTitle:nil
                                 otherButtonTitles:nil];

    [popupQuery addButtonWithTitle:@"Open in Safari"];

    sendMailIndex = -1;
    sendTweetIndex = -1;
    saveRollIndex = -1;

    if ([MFMailComposeViewController canSendMail]) {
        sendMailIndex = [popupQuery addButtonWithTitle:@"Mail link to photo"];
    }
    
    // TODO - This will probably break IOS4 devices.
    if (NSClassFromString(@"TWTweetComposeViewController")) {
        if ([TWTweetComposeViewController canSendTweet]) {
            sendTweetIndex = [popupQuery addButtonWithTitle:@"Tweet link to photo"];
        }
    }
    
    saveRollIndex = [popupQuery addButtonWithTitle:@"Save image to camera roll"];

    popupQuery.cancelButtonIndex = [popupQuery addButtonWithTitle:@"Cancel"];

    popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [popupQuery showFromTabBar:self.tabBarController.tabBar];

    
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [[UIApplication sharedApplication] openURL:self.photo.mobilePageURL];

    } else if (buttonIndex == sendMailIndex) {
        MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
        composer.mailComposeDelegate = self;
        [composer setSubject:self.photo.title];
        // TODO - get url for noticings in here?
        NSString *body;
        if (self.photo.hasTitle) {
            body = [NSString stringWithFormat:@"\"%@\" by %@\n\n%@\n\nSent using Noticings\n", self.photo.title, self.photo.ownername, self.photo.pageURL];
        } else {
            body = [NSString stringWithFormat:@"A photo by %@\n\n%@\n\nSent using Noticings\n", self.photo.ownername, self.photo.pageURL];
        }
        [composer setMessageBody:body isHTML:NO];
        [self presentModalViewController:composer animated:YES];

    } else if (buttonIndex == sendTweetIndex) {
        TWTweetComposeViewController *composer = [[TWTweetComposeViewController alloc] init];
        if (self.photo.hasTitle) {
            [composer setInitialText:self.photo.title];
        } else {
            [composer setInitialText:@"A photo"];
        }
        [composer addURL:self.photo.pageURL];
        [self presentModalViewController:composer animated:YES];

    } else if (buttonIndex == saveRollIndex) {
        // trust the cache. Probably unsafe.
        // TODO - pretty progress views and things
        NSData *imageData = [NSData dataWithContentsOfURL:self.photo.imageURL];
        UIImage *image = [UIImage imageWithData:imageData];
        if (image) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        } else {
            // TODO. Bugger.
        }

    }
}


-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissModalViewControllerAnimated:YES];
}


- (void)viewWillAppear:(BOOL)animated;
{
    NSLog(@"%@ will appear and display %@", self.class, self.photo);
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

    PhotoLocationManager *locationManager = [NoticingsAppDelegate delegate].photoLocationManager;
    if (self.photo.hasLocation) {
        self.photoLocation = [locationManager cachedLocationForPhoto:self.photo];
        if (!self.photoLocation) {
            self.photoLocation = self.photo.placename;
            [locationManager getLocationForPhoto:self.photo andTell:self];
        }
    } else {
        self.photoLocation = nil;
    }

    [self updateHTML];

    
    // load comments
    NSDictionary *args = @{@"photo_id": self.photo.flickrId};

    [[NoticingsAppDelegate delegate].flickrCallManager
     callFlickrMethod:@"flickr.photos.comments.getList"
     asPost:NO
     withArgs:args
     andThen:^(NSDictionary* rsp){
         self.comments = [rsp valueForKeyPath:@"comments.comment"];
         if (!self.comments) {
             self.comments = @[];
         }
         [self updateHTML];
     }
     orFail:^(NSString* code, NSString *err){
         self.commentsError = YES;
         self.comments = nil;
         [self updateHTML];
     }];
}

-(void) gotLocation:(NSString*)location forPhoto:(StreamPhoto*)photo;
{
    self.photoLocation = location;
    [self updateHTML];
}

-(void)viewWillDisappear:(BOOL)animated;
{
    NSLog(@"%@ will disappear", self.class);
    [super viewWillDisappear:animated];
}

-(void)loadedImage:(UIImage *)image forURL:(NSURL*)url cached:(BOOL)cached;
{
    NSLog(@"%@ has loaded an image!", self.class);
    [self updateHTML];
}



-(void)updateHTML;
{
    if (!template) {
        NSLog(@"first run - need to parse template.");
        NSError *err = nil;
        NSString *file = [[NSBundle mainBundle] pathForResource:@"StreamPhotoViewController" ofType:@"html" inDirectory:nil];
        template = [GRMustacheTemplate templateFromContentsOfFile:file error:&err];
        if (err != nil) {
            NSLog(@"error parsing template: %@", err);
            return;
        }
        NSLog(@"parsed");
    }


    NSMutableDictionary *templateData = [NSMutableDictionary dictionary];
    [templateData setValue:self.photo forKey:@"photo"];
    [templateData setValue:self.photoLocation forKey:@"location"];
    
    [templateData setValue:[NSNumber numberWithBool:(self.photo.visibility == StreamPhotoVisibilityPrivate)] forKey:@"isPrivate"];
    [templateData setValue:[NSNumber numberWithBool:(self.photo.visibility == StreamPhotoVisibilityPublic)] forKey:@"isPublic"];
    [templateData setValue:[NSNumber numberWithBool:(self.photo.visibility == StreamPhotoVisibilityLimited)] forKey:@"isLimited"];

    [templateData setValue:[NSNumber numberWithBool:(self.photo.humanTags.count > 0)] forKey:@"hasTags"];

    [templateData setValue:[NSNumber numberWithBool:(self.comments != nil)] forKey:@"loadedComments"];
    [templateData setValue:[NSNumber numberWithBool:(self.comments.count > 0)] forKey:@"hasComments"];
    [templateData setValue:[NSNumber numberWithBool:(self.comments == nil && !self.commentsError)] forKey:@"loadingComments"];
    [templateData setValue:@((self.commentsError)) forKey:@"failedComments"];

    [templateData setValue:self.comments forKey:@"comments"];
    [templateData setValue:[NSNumber numberWithInt:self.comments.count] forKey:@"commentCount"];
    [templateData setValue:[NSNumber numberWithBool:self.photo.isfavorite.intValue] forKey:@"isfavorite"];
    
    id pluralizeHelper = [GRMustacheHelper helperWithBlock:(^(GRMustacheSection *section) {
        NSString *count = [section valueForKey:@"description"];
        NSString *contents = [section render];
        NSString *result = [NSString stringWithFormat:@"%@ %@%@", count, contents, ([count isEqualToString:@"1"] ? @"" : @"s")];
        return result;
    })];
    templateData[@"pluralizeHelper"] = pluralizeHelper;
    
    id dateHelper = [GRMustacheHelper helperWithBlock:^NSString *(GRMustacheSection *section) {
        NSLog(@"section is %@", section);
        double timestamp = [[section render] doubleValue];

        // TODO - copied out of StreamPhoto/ago - refactor.
        NSTimeInterval epoch = [[NSDate date] timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970; // yeah.
        int ago = epoch - timestamp;
        if (ago < 0) {
            return @"a moment ago";
        }
        
        NSLog(@"ago is %f - %f = %d", epoch, timestamp, ago);
        int seconds = ago % 60;
        int minutes = (ago / 60) % 60;
        int hours = (ago / (60*60)) % 24;
        int days = (ago / (24*60*60));
        int months = (ago / (24*60*60*30));
        NSLog(@"%d/%d/%d/%d/%d", months, days, hours, minutes, seconds);
        
        // >1 here partially to make things more precise when they're small numbers (75 mins better 
        // than 1 hour, for instance) but mostly so I don't have to remove the 's' for the ==1 case. :-)
        if (months > 1) {
            return [NSString stringWithFormat:@"%d months ago", months];
        } else {
            days += months * 30;
        }
        if (days > 1) {
            return [NSString stringWithFormat:@"%d days ago", days];
        } else {
            hours += days * 24;
        }
        if (hours > 1) {
            return [NSString stringWithFormat:@"%d hours ago", hours];
        } else {
            minutes += hours * 60;
        }
        if (minutes > 1) {
            return [NSString stringWithFormat:@"%d minutes ago", minutes];
        } else {
            seconds += minutes * 60;
        }
        return [NSString stringWithFormat:@"%d seconds ago", seconds];
    }];
    templateData[@"dateHelper"] = dateHelper;
    
    NSLog(@"rendering with %@", templateData);
    NSString *rendered = [template renderObject:templateData];
//    NSLog(@"rendered as %@", rendered);
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    [self.webView loadHTMLString:rendered baseURL:baseURL];
}

// open links in the webview using the system browser
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {

        if ([request.URL.scheme isEqualToString:@"noticings-image"]) {
            ImageViewController *imageViewController = [[ImageViewController alloc] initWithPhoto:self.photo];
            [self.navigationController pushViewController:imageViewController animated:YES];
            return false;

        } else if ([request.URL.scheme isEqualToString:@"noticings-map"]) {
            MapViewController *mapController = [[MapViewController alloc] init];
            [self.navigationController pushViewController:mapController animated:YES];
            [mapController displayPhoto:self.photo inManager:self.streamManager];
            return false;

        } else if ([request.URL.scheme isEqualToString:@"noticings-user"]) {
            NSArray *list = [request.URL.absoluteString componentsSeparatedByString:@":"];
            
            UserStreamManager *manager;
            if (list.count > 2) {
                NSString *userId = [list[1] stringByDecodingFromURI];
                manager = [[UserStreamManager alloc] initWithUser:userId];
            } else {
                manager = [[UserStreamManager alloc] initWithUser:self.photo.ownerId];
            }
            StreamViewController *userController = [[StreamViewController alloc] initWithPhotoStreamManager:manager];
            if (list.count > 2) {
                NSString *title = [list[2] stringByDecodingFromURI];
                userController.title = title;
            } else {
                userController.title = self.photo.ownername;
            }
            [self.navigationController pushViewController:userController animated:YES];
            return false;

        } else if ([request.URL.scheme isEqualToString:@"noticings-tag"]) {
            NSArray *list = [request.URL.absoluteString componentsSeparatedByString:@":"];
            
            if (list.count < 1) {
                return false;
            }
            NSString *tag = [list[1] stringByDecodingFromURI];

            TagStreamManager *manager = [[TagStreamManager alloc] initWithTag:tag];
            StreamViewController *svc = [[StreamViewController alloc] initWithPhotoStreamManager:manager];
            svc.title = tag;
            [self.navigationController pushViewController:svc animated:YES];
            return false;

        } else if ([request.URL.scheme isEqualToString:@"noticings-comment"]) {
            AddCommentViewController *commentController = [[AddCommentViewController alloc] initWithPhoto:self.photo];
            [self.navigationController pushViewController:commentController animated:YES];
            return false;

        } else if ([request.URL.scheme isEqualToString:@"noticings-favorite"]) {

            [[NoticingsAppDelegate delegate].flickrCallManager
             callFlickrMethod:@"flickr.favorites.add"
             asPost:YES
             withArgs:@{@"photo_id": self.photo.flickrId}
             andThen:^(NSDictionary* rsp){
                 NSLog(@"Added fave!");
                 self.photo.isfavorite = [NSNumber numberWithBool:YES];
                 [[NoticingsAppDelegate delegate] savePersistentObjects];
                 [self updateHTML];
             }
             orFail:^(NSString *code, NSString *error){
                 NSLog(@"Can't add fave!!! %@ %@", code, error);
             }];

        } else if ([request.URL.scheme isEqualToString:@"noticings-unfavorite"]) {

            [[NoticingsAppDelegate delegate].flickrCallManager
             callFlickrMethod:@"flickr.favorites.remove"
             asPost:YES
             withArgs:@{@"photo_id": self.photo.flickrId}
             andThen:^(NSDictionary* rsp){
                 NSLog(@"Removed fave!");
                 self.photo.isfavorite = [NSNumber numberWithBool:NO];
                 [[NoticingsAppDelegate delegate] savePersistentObjects];
                 [self updateHTML];
             }
             orFail:^(NSString *code, NSString *error){
                 NSLog(@"Can't rmeove fave!!! %@ %@", code, error);
             }];

        }
        
        // TODO - match flickr.com/photos/XXX/XXX and just open photo page?

        [[UIApplication sharedApplication] openURL:request.URL];
        return false;
    }
    return true;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.webView.delegate = nil;
    self.webView = nil;
    self.comments = nil;
    self.photoLocation = nil;
    self.streamManager = nil;
    self.photo = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)dealloc;
{
    [self viewDidUnload];
}


@end
