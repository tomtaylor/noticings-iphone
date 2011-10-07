//
//  StreamPhotoViewController.m
//  Noticings
//
//  Created by Tom Insam on 30/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "StreamPhotoViewController.h"
#import "StreamPhotoViewCell.h"
#import "UserStreamManager.h"
#import "ImageViewController.h"
#import "MapViewController.h"
#import "StreamViewController.h"
#import "PhotoLocationManager.h"
#import "DeferredFlickrCallManager.h"
#import "TagStreamManager.h"

#import "NSString+HTML.h"
#import "NSString+URI.h"

@implementation StreamPhotoViewController

@synthesize photo, streamManager, photoLocation, webView, comments, commentsError;

-(id)initWithPhoto:(StreamPhoto*)_photo streamManager:(PhotoStreamManager*)_streamManager;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.photo = _photo;
        self.streamManager = _streamManager;
        self.title = self.photo.title; // for nav controller
    }
    return self;
}

-(void)loadView;
{
    [super loadView];
}

-(void)viewDidLoad;
{
    self.webView = [[[UIWebView alloc] initWithFrame:self.view.bounds] autorelease];
    self.webView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.comments = nil;
    self.commentsError = NO;
    self.view.autoresizesSubviews = YES;
    [self.view addSubview:self.webView];

    UIBarButtonItem *externalItem = [[UIBarButtonItem alloc] 
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                     target:self
                                     action:@selector(openInBrowser)];
    
    self.navigationItem.rightBarButtonItem = externalItem;
    [externalItem release];
}

-(void)openInBrowser;
{
    [[UIApplication sharedApplication] openURL:photo.mobilePageURL];
}

- (void)viewWillAppear:(BOOL)animated;
{
    NSLog(@"%@ will appear", self.class);
    [super viewWillAppear:animated];

    // load images, on the off-change we haven't got them already.
    [[CacheManager sharedCacheManager] fetchImageForURL:self.photo.imageURL andNotify:self];
    [[CacheManager sharedCacheManager] fetchImageForURL:self.photo.avatarURL andNotify:self];

    if (self.photo.hasLocation) {
        [[CacheManager sharedCacheManager] fetchImageForURL:self.photo.mapImageURL andNotify:self];

        self.photoLocation = self.photo.placename;
        [[PhotoLocationManager sharedPhotoLocationManager] getLocationForPhoto:photo and:^(NSString* name){
            if (name) {
                self.photoLocation = name;
                [self updateHTML];
            }
        }];
    }
    
    // load comments
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                          self.photo.flickrId, @"photo_id",
                          nil];

    [[DeferredFlickrCallManager sharedDeferredFlickrCallManager]
     callFlickrMethod:@"flickr.photos.comments.getList"
     withArgs:args
     andThen:^(NSDictionary* rsp){
         self.comments = [rsp valueForKeyPath:@"comments.comment"];
         if (!self.comments) {
             self.comments = [NSArray array];
         }
         [self updateHTML];
     }
     orFail:^(NSString* code, NSString *err){
         self.commentsError = YES;
         self.comments = nil;
         [self updateHTML];
     }];

    [self updateHTML];
}

-(void)viewWillDisappear:(BOOL)animated;
{
    NSLog(@"%@ will disappear", self.class);
    [[CacheManager sharedCacheManager] flushQueue];
    [super viewWillDisappear:animated];
}

-(void)loadedImage:(UIImage *)image forURL:(NSURL*)url cached:(BOOL)cached;
{
    NSLog(@"%@ has loaded an image!", self.class);
    [self updateHTML];
}


-(void)updateHTML;
{
    CacheManager *cacheManager = [CacheManager sharedCacheManager];
    
    // beginning to want an actual templating language here. :-)
    
    // Load common HTML heading. TODO - maybe cache as static string, it's a little
    // wasteful to load this all the time?
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"StreamPhotoViewController" ofType:@"html" inDirectory:nil];
    NSString *htmlWrapper = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    
    NSString *html = @"";
    
    NSString *imageFile = [cacheManager urlToFilename:photo.imageURL];
    if ([[NSFileManager defaultManager] fileExistsAtPath:imageFile]) {
        html = [html stringByAppendingFormat:@"<a href='noticings-image:'><img class='image' src='%@'></a>", imageFile];
    } else {
        html = [html stringByAppendingFormat:@"<a href='noticings-image:'><div class='image-loading'></div></a>", imageFile];
    }

    html = [html stringByAppendingFormat:@"<a href='noticings-user:'><img class='avatar' src='%@'></a>", [cacheManager urlToFilename:photo.avatarURL]];

    html = [html stringByAppendingFormat:@"<p class='title'>%@</p>", [photo.title stringByEncodingHTMLEntities]];

    html = [html stringByAppendingFormat:@"<p class='owner'>by <a href='noticings-user:'>%@</a></p>", [photo.ownername stringByEncodingHTMLEntities]];

    html = [html stringByAppendingString:@"</p><div style='clear: both'></div>"];
    

    // Visibility
    NSString *visClass = @"public";
    NSString *visName = @"public";
    if (self.photo.visibility == StreamPhotoVisibilityPrivate) {
        visClass = @"private";
        visName = @"private";
    } else if (self.photo.visibility == StreamPhotoVisibilityLimited) {
        visClass = @"limited";
        visName = @"friends and family only";
    }
    html = [html stringByAppendingFormat:@"<p class='header'>Photo is <span class='%@'>%@</span>. ", visClass, visName];

    // Time ago
    html = [html stringByAppendingFormat:@"Taken %@ ago", [self.photo.ago stringByEncodingHTMLEntities]];

    // location (in same paragraph)
    if (self.photo.hasLocation) {
        html = [html stringByAppendingFormat:@", in <a href='noticings-map:'>%@</a>: ", [self.photoLocation stringByEncodingHTMLEntities]];
    } else {
        html = [html stringByAppendingString:@". "];
    }

    html = [html stringByAppendingString:@"</p>"];

    if (self.photo.hasLocation) {
        NSString *mapFile = [cacheManager urlToFilename:photo.mapImageURL];
        if ([[NSFileManager defaultManager] fileExistsAtPath:mapFile]) {
            html = [html stringByAppendingFormat:@"<a href='noticings-map:'><img class='map' src='%@'></a>", mapFile];
        }
    }    


    // description
    if (self.photo.html) {
        html = [html stringByAppendingFormat:@"<p class='description'>%@</p>", self.photo.html];
    }
    
    if (self.photo.tags.count > 0) {
        html = [html stringByAppendingFormat:@"<p class='tags'>Tagged "];
        
        for (NSString *tag in self.photo.tags) {
            html = [html stringByAppendingFormat:@"<a class='tag' href='noticings-tag:%@'>%@</a> ",
                    [tag stringByEncodingForURI],
                    [tag stringByEncodingHTMLEntities]
            ];
        }
        html = [html stringByAppendingFormat:@"</p>"];
    }
    
    if (self.comments) {
        if (self.comments.count > 0) {
            html = [html stringByAppendingFormat:@"<p class='comments'>%d comment(s):</p>", self.comments.count];
            for (NSDictionary *comment in self.comments) {
                // assume comment body is safe
                html = [html stringByAppendingFormat:@"<p class='comment'><a class='author' href='noticings-user:%@:%@'>%@</a>: %@</p>",
                        [[comment valueForKeyPath:@"author"] stringByEncodingForURI],
                        [[comment valueForKeyPath:@"authorname"] stringByEncodingForURI],
                        [[comment valueForKeyPath:@"authorname"] stringByEncodingHTMLEntities],
                        [comment valueForKeyPath:@"_text"]
                ];
            }
        } else {
            html = [html stringByAppendingFormat:@"<p class='comments'>No comments.</p>"];
        }
    } else if (self.commentsError) {
        html = [html stringByAppendingFormat:@"<p class='comments'>Failed to load comments.</p>"];
    } else {
        html = [html stringByAppendingFormat:@"<p class='comments'>Loading comments...</p>"];
    }
    html = [html stringByAppendingFormat:@"<p class='add-comment'><a href='noticings-comment:'>Add comment</a></p>"];
    

    // TODO - if it's already loaded, try to not disrupt the scroll position.
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    [self.webView loadHTMLString:[NSString stringWithFormat:htmlWrapper, html] baseURL:baseURL];
}

// open links in the webview using the system browser
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {

        if ([request.URL.scheme isEqualToString:@"noticings-image"]) {
            ImageViewController *imageViewController = [[ImageViewController alloc] initWithPhoto:self.photo];
            [self.navigationController pushViewController:imageViewController animated:YES];
            [imageViewController release];
            return false;

        } else if ([request.URL.scheme isEqualToString:@"noticings-map"]) {
            MapViewController *mapController = [[MapViewController alloc] init];
            [self.navigationController pushViewController:mapController animated:YES];
            [mapController displayPhoto:photo inManager:self.streamManager];
            [mapController release];
            return false;

        } else if ([request.URL.scheme isEqualToString:@"noticings-user"]) {
            NSArray *list = [request.URL.absoluteString componentsSeparatedByString:@":"];
            
            UserStreamManager *manager;
            if (list.count > 2) {
                NSString *userId = [[list objectAtIndex:1] stringByDecodingFromURI];
                manager = [[UserStreamManager alloc] initWithUser:userId];
            } else {
                manager = [[UserStreamManager alloc] initWithUser:photo.ownerId];
            }
            StreamViewController *userController = [[StreamViewController alloc] initWithPhotoStreamManager:manager];
            [manager release];
            if (list.count > 2) {
                NSString *title = [[list objectAtIndex:2] stringByDecodingFromURI];
                userController.title = title;
            } else {
                userController.title = photo.ownername;
            }
            [self.navigationController pushViewController:userController animated:YES];
            [userController release];
            return false;

        } else if ([request.URL.scheme isEqualToString:@"noticings-tag"]) {
            NSArray *list = [request.URL.absoluteString componentsSeparatedByString:@":"];
            
            if (list.count < 1) {
                return false;
            }
            NSString *tag = [[list objectAtIndex:1] stringByDecodingFromURI];
            NSLog(@"tapped tag %@", tag);

            TagStreamManager *manager = [[TagStreamManager alloc] initWithTag:tag];
            StreamViewController *svc = [[StreamViewController alloc] initWithPhotoStreamManager:manager];
            [manager release];
            svc.title = tag;
            [self.navigationController pushViewController:svc animated:YES];
            [svc release];
            return false;

        } else if ([request.URL.scheme isEqualToString:@"noticings-comment"]) {
            // TODO
            UIViewController *commentController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
            commentController.title = @"Add comment";
            [self.navigationController pushViewController:commentController animated:YES];
            [commentController release];
            return false;

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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)dealloc;
{
    if (self.webView) {
        self.webView.delegate = nil;
    }
    self.webView = nil;
    self.comments = nil;
    self.photoLocation = nil;
    self.streamManager = nil;
    self.photo = nil;
    [super dealloc];
}


@end
