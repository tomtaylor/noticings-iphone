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
    if (![[NoticingsAppDelegate delegate] isAuthenticated]) {
        DLog(@"not authenticated - not reloading");
        return;
    }

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
    [self.delegate photoStreamManagerStartedRefresh:self];
    
    NSLog(@"Calling Flickr");
    [self callFlickrAnd:^(BOOL success, NSDictionary *rsp, NSError *error) {
        self.inProgress = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

        if (!success) {
            NSLog(@"failed flickr request! %@ %@", rsp, error);
            [[[UIAlertView alloc] initWithTitle:@"Flickr API call failed"
                                         message:@"There was a problem getting your contacts' photos from Flickr."
                                        delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil] show];
            
            // call newPhotos call _anyway_, to convince the view controller that we're finished.
            [self.delegate performSelector:@selector(newPhotos)];
            return;
        }

        [self.rawPhotos removeAllObjects];
        for (NSDictionary *photo in [rsp valueForKeyPath:@"photos.photo"]) {
            StreamPhoto *sp = [StreamPhoto photoWithDictionary:photo];
            [self.rawPhotos addObject:sp];
        }
        [[NoticingsAppDelegate delegate] savePersistentObjects];
        [self saveCachedImageList];
        
        self.lastRefresh = [[NSDate date] timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970;

        NSLog(@"loaded %d photos", [self.rawPhotos count]);
        if (self.delegate) {
            [self.delegate performSelector:@selector(newPhotos)];
        }
        
        // now update dirty photos
        for (StreamPhoto *photo in self.rawPhotos) {
            if ([photo.needsFetch boolValue]) {
                if (self.photoInfoFetcher == nil) {
                    self.photoInfoFetcher = [[NSOperationQueue alloc] init];
                    self.photoInfoFetcher.maxConcurrentOperationCount = 1;
                }
                [self.photoInfoFetcher addOperationWithBlock:^{
                    if ([photo.needsFetch boolValue]) {
                        DLog(@"photo %@ needs metadata fetch", photo);
                        NSError *error = nil;
                        NSDictionary *rsp = [[NoticingsAppDelegate delegate].flickrCallManager
                                             callSynchronousFlickrMethod:@"flickr.photos.getInfo"
                                             asPost:NO
                                             withArgs:@{@"photo_id":photo.flickrId}
                                             error:&error];
                        if (!error && [rsp objectForKey:@"photo"]) {
                            [photo updateFromPhotoInfo:[rsp objectForKey:@"photo"]];
                            // would be nicer to do this at the end? do we care?
                            [[NoticingsAppDelegate delegate] savePersistentObjects];
                            DLog(@"fetched and saved %@", photo);
                            [[NSNotificationCenter defaultCenter] postNotificationName:PHOTO_CHANGED_NOTIFICATION object:photo];

                        } else {
                            DLog(@"problem fetching %@: %@", photo, error);
                        }
                    }
                }];
            }
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

-(void)flickrInfoFor:(NSString*)flickrId callback:(FlickrCallback)callback;
{
    NSDictionary *args = @{@"photo_id":flickrId};
    [[NoticingsAppDelegate delegate].flickrCallManager callFlickrMethod:@"flickr.photos.getInfo"
                                                                 asPost:NO
                                                               withArgs:args
                                                                andThen:callback];
}

-(NSString*)extras;
{
    return @"date_upload,date_taken,owner_name,icon_server,geo,path_alias,description,url_m,url_o,url_b,tags,media,last_update";
}

- (void)resetFlickrContext;
{
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
    if (![self cacheFilename] || [self cacheFilename].length == 0) {
        DLog(@"this view has no cache");
        return;
    }

    // TODO - error handling? what if the cache is bad?
    NSString* cache = [[NoticingsAppDelegate delegate].cacheManager cachePathForFilename:[self cacheFilename]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cache]) {
        DLog(@"No cache for image list at %@", cache);
        return; // no cache
    }
    NSLog(@"Loading cached image data from %@", cache);
    NSData *data = [[NSData alloc] initWithContentsOfFile:cache];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSArray *archived = [unarchiver decodeObjectForKey:@"photoIds"];
    NSNumber *archivedLastRefresh = [unarchiver decodeObjectForKey:@"lastRefresh"];
    
    // don't replace self.photos, alter, so we fire the watchers.
    [self.rawPhotos removeAllObjects];
    for (NSString *flickrId in archived) {
        StreamPhoto *photo = [StreamPhoto photoWithFlickrId:flickrId];
        if (photo != nil) {
            [self.rawPhotos addObject:photo];
        }
    }

    self.lastRefresh = [archivedLastRefresh doubleValue];
}

// save the cached list of images fetched from flickr
-(void)saveCachedImageList;
{
    if ([self cacheFilename].length == 0) {
        return;
    }

    NSString* cache = [[NoticingsAppDelegate delegate].cacheManager cachePathForFilename:[self cacheFilename]];
    NSLog(@"Saving cached image data to %@", cache);
    // store just the Ids of the photos in this view
    NSMutableArray *photoIds = [NSMutableArray arrayWithCapacity:self.rawPhotos.count];
    for (StreamPhoto *photo in self.rawPhotos) {
        [photoIds addObject:photo.flickrId];
    }
    NSMutableData *data = [NSMutableData new];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:photoIds forKey:@"photoIds"];
    [archiver encodeObject:@(self.lastRefresh) forKey:@"lastRefresh"];
    [archiver finishEncoding];
    [data writeToFile:cache atomically:YES];
}

-(void)precache;
{
    NSLog(@"pre-caching images for %@", self.class);
    
    __weak PhotoStreamManager* _self = self;
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
}


@end
