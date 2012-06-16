//
//  StreamViewController.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamViewController.h"
#import "StreamPhotoViewCell.h"
#import "StreamPhoto.h"
#import "CacheManager.h"
#import "PhotoUploadCell.h"
#import "ContactsStreamManager.h"
#import "StreamPhotoViewController.h"
#import "NoticingsAppDelegate.h"
#import "PhotoUploadOperation.h"

@interface StreamViewController (Private)
- (void)setQueueButtonState;
- (void)queueButtonPressed;
@end

@implementation StreamViewController

@synthesize streamManager, maybeCancel;

-(id)initWithPhotoStreamManager:(PhotoStreamManager*)manager;
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.streamManager = manager;
        self.streamManager.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
    
    isRoot = NO;
    if (!self.streamManager) {
        // we were initialized from the nib, without going through the custom init above,
        // so we must be the root controller.
        self.streamManager = [NoticingsAppDelegate delegate].contactsStreamManager;
        self.streamManager.delegate = self;
        isRoot = YES;
    }
    
    // hack the internals of the pull-to-refresh controller so I can display a second line.
    // TODO - ideally, I'd display the second line in a fainter colour / not bold / something.
    self.refreshLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.refreshLabel.numberOfLines = 2;
    
    if (isRoot) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(uploadQueueDidChange) 
                                                     name:@"queueCount" 
                                                   object:nil];
    }

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewDidUnload
{
    // we need to unsubscribe, in case they fire and it no longer exists
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

-(void)updatePullText;
{
    self.textPull = [NSString stringWithFormat:@"Pull to refresh..\nLast refreshed %@", streamManager.lastRefreshDisplay];
    self.textRelease = [NSString stringWithFormat:@"Release to refresh..\nLast refreshed %@", streamManager.lastRefreshDisplay];
    self.textLoading = [NSString stringWithFormat:@"Loading..\nLast refreshed %@", streamManager.lastRefreshDisplay];
}

-(void)viewWillAppear:(BOOL)animated;
{
    if (isRoot) {
        // hide navigation bar, only for root controller
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [self updatePullText];
}

-(void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
    [self.streamManager maybeRefresh];
	[self.tableView reloadData]; // reload here to update the "no photos" message to be "loading"
}

-(void)viewWillDisappear:(BOOL)animated;
{
    [super viewWillDisappear:animated];
    if (isRoot) {
        // hide navigation bar, only for root controller
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }
}


// delegate callback method from PhotoStreamManager
- (void)newPhotos;
{
    NSLog(@"new photos loaded for %@", self.class);
    [self stopLoading]; // for the pull-to-refresh thing
    [self updatePullText];

    // are we the currently-active view controller? Precache if so.
    if (self.isViewLoaded && self.view.window) {
        NSLog(@"View is visible. Pre-caching.");
        [self.streamManager precache];
    }
    
    // the root view controller can offer to turn on "filter instagram" if it sees
    // photos in the list that are from instagram. This is a one-time offer, because it's
    // a little expensive.
    BOOL askedToFilterInstagram = [[NSUserDefaults standardUserDefaults] boolForKey:@"askedToFilterInstagram"];
    BOOL filterInstagram = [[NSUserDefaults standardUserDefaults] boolForKey:@"filterInstagram"];
    if (isRoot && !askedToFilterInstagram && !filterInstagram) {
        NSArray *instagramPhotos = [self.streamManager.rawPhotos filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            StreamPhoto *sp = (StreamPhoto*)evaluatedObject;
            if ([sp.tags filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                NSString *tag = (NSString*)evaluatedObject;
                return [tag isEqualToString:@"uploaded:by=instagram"];
            }]].count > 0) {
                return YES;
            }
            return NO;
        }]];
        if (instagramPhotos.count > 6) { // this number by hand-waving
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"oooh, Instagram."
                                                            message:@"I see some Instagram photos from your contacts here. If you prefer to look at them with the Real Instagram client, I can hide them from this view for you (change this back in Settings)."
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:nil];
            [alert addButtonWithTitle:@"Hide"];
            [alert addButtonWithTitle:@"Show"];
            [alert show];
            [alert release];
        }
        
        
        // whatever happens, don't do that again.
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:@"askedToFilterInstagram"];
    }

	[self.tableView reloadData];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    NSLog(@"button %d", buttonIndex);
    if (buttonIndex == 1) {
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:@"filterInstagram"];
        [self.tableView reloadData];
    }
}

- (void)uploadQueueDidChange
{
    [self.tableView reloadData];
}

- (void)refresh;
{
    [streamManager refresh];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (StreamPhoto *)streamPhotoAtIndexPath:(NSIndexPath*)indexPath {
    NSArray *photos = streamManager.filteredPhotos;
    if ([photos count] == 0) {
        return nil;
    }
    
    if (!isRoot) {
        // for the non-root controller, just index into Photos.
        NSInteger photoIndex = indexPath.section;
        return [photos objectAtIndex:photoIndex];
    }

    UploadQueueManager *uploadQueueManager = [NoticingsAppDelegate delegate].uploadQueueManager;
    int photoUploads = uploadQueueManager.queue.operationCount;
    if (indexPath.section < photoUploads) {
        // upload cell
        return nil;
    }

    NSInteger photoIndex = indexPath.section - photoUploads;
    return [photos objectAtIndex:photoIndex];
}

- (PhotoUpload*)photoUploadAtIndexPath:(NSIndexPath*)indexPath;
{
    // only the root controller has upload cells
    if (!isRoot) {
        return nil;
    }

    UploadQueueManager *uploadQueueManager = [NoticingsAppDelegate delegate].uploadQueueManager;
    NSArray *photoUploadOperations = uploadQueueManager.queue.operations;
    if ([photoUploadOperations count] == 0) {
        return nil;
    }
    if (indexPath.section < [photoUploadOperations count]) {
        return ((PhotoUploadOperation*)[photoUploadOperations objectAtIndex:indexPath.section]).upload;
    }
    return nil;
}

// return a table cell for a photo without firing off a background "fetch the URL from flickr"
// call. this is a nasty fudge so that I can get the cell height without causing network activity,
// but it's a lot of overhead.
-(StreamPhotoViewCell*)passiveTableCellForPhoto:(StreamPhoto*)photo;
{
    static NSString *MyIdentifier = @"StreamPhotoViewCell";
    StreamPhotoViewCell *cell = (StreamPhotoViewCell *)[self.tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"StreamPhotoViewCell" owner:self options:nil];
        cell = photoViewCell;
        photoViewCell = nil;
    }
    [cell populateFromPhoto:photo];
    return cell;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSArray *photos = self.streamManager.filteredPhotos;
	NSInteger photosCount = photos.count == 0 ? 1 : photos.count;
    if (isRoot) {
        UploadQueueManager *uploadQueueManager = [NoticingsAppDelegate delegate].uploadQueueManager;
        return photosCount + uploadQueueManager.queue.operationCount;
    } else {
        return photosCount;
    }
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PhotoUpload *upload = [self photoUploadAtIndexPath:indexPath];
    if (upload) {
        static NSString *MyIdentifier = @"StreamPhotoUploadCell";
        PhotoUploadCell *cell = (PhotoUploadCell *)[self.tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"PhotoUploadCell" owner:self options:nil];
            cell = photoUploadCell;
            photoUploadCell = nil;
        }
        [cell displayPhotoUpload:upload];
        return cell;
    }
    
    StreamPhoto *photo = [self streamPhotoAtIndexPath:indexPath];
    if (photo) {
        StreamPhotoViewCell *cell = [self passiveTableCellForPhoto:photo];
        return cell;
    }
    
    // no photos to display. Placeholder.
    // TODO - if this is the first run, this might be because we haven't loaded any
    // photos yet.
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    if (self.streamManager.inProgress) {
        cell.textLabel.text = @"Loading photos...";
    } else {
        cell.textLabel.text = @"No photos to display.";
    }
    cell.textLabel.textColor = [UIColor grayColor];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return [cell autorelease];
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    StreamPhoto *photo = [self streamPhotoAtIndexPath:indexPath];
    if (photo) {
        return [StreamPhotoViewCell cellHeightForPhoto:photo];
    }
    return 81; // upload cells.
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{

    StreamPhoto *photo = [self streamPhotoAtIndexPath:indexPath];
    if (photo) {
        StreamPhotoViewController *vc = [[StreamPhotoViewController alloc] initWithPhoto:photo streamManager:self.streamManager];
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
        return;
    }

    PhotoUpload *upload = [self photoUploadAtIndexPath:indexPath];
    if (upload) {
        DLog(@"maybe cancelling upload %@", upload);
        self.maybeCancel = upload;
        UIActionSheet *popupQuery = [[UIActionSheet alloc]
                                     initWithTitle:nil
                                     delegate:self
                                     cancelButtonTitle:@"Continue"
                                     destructiveButtonTitle:@"Cancel upload"
                                     otherButtonTitles:nil];
        
        popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
        [popupQuery showFromTabBar:self.tabBarController.tabBar];
        [popupQuery release];
        return;
    }
    
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex && self.maybeCancel) {
        [[NoticingsAppDelegate delegate].uploadQueueManager cancelUpload:self.maybeCancel];
    }
    self.maybeCancel = nil;
}

# pragma mark memory management

- (void)dealloc {
    NSLog(@"deallocing %@", self.class);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.streamManager.delegate = nil;
    self.streamManager = nil;
    [super dealloc];
}


@end

