//
//  PhotoStreamManager.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import "PhotoStreamManager.h"

#import "APIKeys.h"
#import "NoticingsAppDelegate.h"

@implementation PhotoStreamManager

@synthesize rawPhotos;
@synthesize inProgress;
@synthesize lastRefresh;
@synthesize delegate;

- (id)init;
{
    self = [super init];
    if (self) {
        self.rawPhotos = [NSMutableArray arrayWithCapacity:50];
        self.inProgress = NO;

        // It's worth blocking the runloop during app startup while we check
        // the cache, to avoid a flash of empty photo list.
        [self loadCachedImageList];
    }
    
    return self;
}

// refresh, but only if we haven't refreshed recently.
-(void)maybeRefresh;
{
    NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970;
    NSLog(@"it's been %f seconds since refresh", now - self.lastRefresh);
    if (now - self.lastRefresh < 60 * 10) {
        // 10 mins
        NSLog(@"not long enough");
        return;
    }
    [self refresh];
}

- (void)refresh;
{
    if (self.inProgress) {
        NSLog(@"Refresh already in progress, refusing to go again.");
        return;
    }
    
    self.inProgress = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSLog(@"Calling Flickr");
    [self callFlickrAnd:^(BOOL success, NSDictionary *rsp, NSError *error) {
        self.inProgress = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

        if (!success) {
            NSLog(@"failed flickr request! %@", error);
            [[[[UIAlertView alloc] initWithTitle:@"Flickr API call failed"
                                         message:@"There was a problem getting your contacts' photos from Flickr."
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil]
              autorelease] show];
            
            // call newPhotos call _anyway_, to convince the view controller that we're finished.
            [self.delegate performSelector:@selector(newPhotos)];
            return;
        }

        [self.rawPhotos removeAllObjects];
        for (NSDictionary *photo in [rsp valueForKeyPath:@"photos.photo"]) {
            StreamPhoto *sp = [[StreamPhoto alloc] initWithDictionary:photo];
            [self.rawPhotos addObject:sp];
            [sp release];
        }
        [self saveCachedImageList];
        
        self.lastRefresh = [[NSDate date] timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970;

        NSLog(@"loaded %d photos", [self.rawPhotos count]);
        if (self.delegate) {
            [self.delegate performSelector:@selector(newPhotos)];
        }
        
    }];
    
}

-(NSString*)lastRefreshDisplay;
{
    if (!self.lastRefresh) {
        return @"never";
    }
    NSDate *refresh = [NSDate dateWithTimeIntervalSinceReferenceDate:self.lastRefresh - NSTimeIntervalSince1970];
    NSDateFormatterStyle dateStyle = NSDateFormatterShortStyle;
    NSDateFormatterStyle timeStyle = NSDateFormatterShortStyle;
    return [NSDateFormatter localizedStringFromDate:refresh dateStyle:dateStyle timeStyle:timeStyle];
}

-(void)callFlickrAnd:(FlickrCallback)callback;
{
    // override in subclass
    NSLog(@"can't use superclass PhotoStreamManager without implementing callFlickr!!");
    assert(FALSE);
}

-(NSString*)extras;
{
    return @"date_upload,date_taken,owner_name,icon_server,geo,path_alias,description,url_m,url_o,url_b,tags,media";
}

- (void)resetFlickrContext;
{
    NSLog(@"binning flickr request");
    self.inProgress = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(NSString*)cacheFilename;
{
    return @""; 
}

// load the cached list of images fetched from flickr
-(void)loadCachedImageList;
{
    if ([self cacheFilename].length == 0) {
        return;
    }

    // TODO - error handling? what if the cache is bad?
    NSString* cache = [[NoticingsAppDelegate delegate].cacheManager cachePathForFilename:[self cacheFilename]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cache]) {
        DLog(@"No cache for image list");
        return; // no cache
    }
    NSLog(@"Loading cached image data from %@", cache);
    NSData *data = [[NSData alloc] initWithContentsOfFile:cache];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSArray *archived = [[unarchiver decodeObjectForKey:@"photos"] retain];
    NSNumber *archivedLastRefresh = [[unarchiver decodeObjectForKey:@"lastRefresh"] retain];
    [unarchiver release];
    [data release];
    
    // don't replace self.photos, alter, so we fire the watchers.
    [self.rawPhotos removeAllObjects];
    for (StreamPhoto *photo in archived) {
        [self.rawPhotos addObject:photo];
    }
    [archived release];

    self.lastRefresh = [archivedLastRefresh doubleValue];
    [archivedLastRefresh release];
}

// save the cached list of images fetched from flickr
-(void)saveCachedImageList;
{
    if ([self cacheFilename].length == 0) {
        return;
    }

    NSString* cache = [[NoticingsAppDelegate delegate].cacheManager cachePathForFilename:[self cacheFilename]];
    NSLog(@"Saving cached image data to %@", cache);
    NSMutableData *data = [NSMutableData new];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:self.rawPhotos forKey:@"photos"];
    [archiver encodeObject:@(self.lastRefresh) forKey:@"lastRefresh"];
    [archiver finishEncoding];
    [data writeToFile:cache atomically:YES];
    [archiver release];
    [data release];
}

-(void)precache;
{
    NSLog(@"pre-caching images for %@", self.class);
    
    __block PhotoStreamManager* _self = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{

        // pre-cache images
        //PhotoLocationManager *locationManager = [PhotoLocationManager sharedPhotoLocationManager];
        
        for (StreamPhoto *sp in _self.filteredPhotos) {
            [NSData dataWithContentsOfURL:sp.avatarURL];
            [NSData dataWithContentsOfURL:sp.imageURL];
//            if (sp.hasLocation) {
//                [NSData dataWithContentsOfURL:sp.mapImageURL];
//            }
            //if (![locationManager cachedLocationForPhoto:sp]) {
            //    [locationManager getLocationForPhoto:sp andTell:nil];
            //}
        }

    });    
}

-(NSArray*)filteredPhotos;
{
    return [NSArray arrayWithArray:self.rawPhotos];
}

- (void)dealloc
{
    NSLog(@"deallocing %@", self.class);
    self.delegate = nil;
    self.rawPhotos = nil;
    [super dealloc];
}


@end
