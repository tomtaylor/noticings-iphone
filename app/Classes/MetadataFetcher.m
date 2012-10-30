//
//  MetadataFetcher.m
//  Noticings
//
//  Created by Tom Insam on 2012/10/30.
//
//

#import "MetadataFetcher.h"
#import "StreamPhoto.h"
#import "NoticingsAppDelegate.h"

@implementation MetadataFetcher

-(id)init;
{
    self = [super init];
    if (self != nil) {
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 1; // TODO - increase for ship
    }
    return self;
}

- (void)fetchPhotos;
{
    NSArray *photos = [StreamPhoto photosWithPredicate:[NSPredicate predicateWithFormat:@"needsFetch = true"]];
    for (StreamPhoto *photo in photos) {
        [self.queue addOperationWithBlock:^{
            // test again here to allow for photos being added to the queue more
            // than once - we're pretty aggressive, but this lets me just zap
            // through the rest of the queue once everything is actually fetched.
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

@end
