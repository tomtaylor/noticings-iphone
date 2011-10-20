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

@interface StreamViewController (Private)
- (void)setQueueButtonState;
- (void)queueButtonPressed;
@end

@implementation StreamViewController

@synthesize streamManager;

-(id)initWithPhotoStreamManager:(PhotoStreamManager*)manager;
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.streamManager = manager;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL isRoot = NO;
    if (!self.streamManager) {
        self.streamManager = [ContactsStreamManager sharedContactsStreamManager];
        isRoot = YES; // crude
    }
    
    self.refreshLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.refreshLabel.numberOfLines = 2;
    [self updatePullText];
    
    self.streamManager.delegate = self;

    if (isRoot) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(uploadQueueDidChange) 
                                                     name:@"queueCount" 
                                                   object:nil];
        
        if (uploadQueueManager == nil) {
            uploadQueueManager = [UploadQueueManager sharedUploadQueueManager];
        }
            
        [uploadQueueManager addObserver:self
                             forKeyPath:@"inProgress"
                                options:(NSKeyValueObservingOptionNew)
                                context:NULL];
        
        if (queueButton == nil) {
            queueButton = [[UIBarButtonItem alloc] 
                           initWithTitle:@"Pause Queue" 
                           style:UIBarButtonItemStylePlain 
                           target:self
                           action:@selector(queueButtonPressed)];
        }
        
        [self setQueueButtonState];
    }

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // we need to unsubscribe, in case they fire and it no longer exists
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // tear this down too - it'll be reassigned and subscribed when viewDidLoad is called again
    if (uploadQueueManager) {
        [uploadQueueManager removeObserver:self forKeyPath:@"inProgress"];
        [uploadQueueManager release];
        uploadQueueManager = nil;
    }
    
}

-(void)updatePullText;
{
    self.textPull = [NSString stringWithFormat:@"Pull to refresh..\nLast refreshed %@", streamManager.lastRefreshDisplay];
    self.textRelease = [NSString stringWithFormat:@"Release to refresh..\nLast refreshed %@", streamManager.lastRefreshDisplay];
    self.textLoading = [NSString stringWithFormat:@"Loading..\nLast refreshed %@", streamManager.lastRefreshDisplay];
}

-(void)viewWillAppear:(BOOL)animated;
{
    NSLog(@"%@ will appear", self.class);
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
    [self.streamManager maybeRefresh];
	[self.tableView reloadData];
    //[self.streamManager precache];
}

-(void)viewWillDisappear:(BOOL)animated;
{
    NSLog(@"%@ will disappear", self.class);
    [[CacheManager sharedCacheManager] flushQueue];
    [super viewWillDisappear:animated];
}


// delegate callback method from PhotoStreamManager
- (void)newPhotos;
{
    NSLog(@"new photos loaded for %@", self.class);
    [self stopLoading]; // for the pull-to-refresh thing
    [self updatePullText];

    // are we the currently-active view controller? Precache if so.
    if (self.isViewLoaded && self.view.window) {
        // flush the queue first, so we load the top images asap.
        NSLog(@"View is visible. Pre-caching.");
        [[CacheManager sharedCacheManager] flushQueue];
        [self.streamManager precache];
    }

	[self.tableView reloadData];
}




- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	[self setQueueButtonState];
}

- (void)uploadQueueDidChange
{
    [self setQueueButtonState];
    [self.tableView reloadData];
}

- (void)setQueueButtonState
{
    if ([uploadQueueManager.photoUploads count] > 0) {
        if (uploadQueueManager.inProgress) {
            queueButton.title = @"Pause Queue";
        } else {
            queueButton.title = @"Start Queue";
        }
        if (self.navigationItem.rightBarButtonItem == nil) {
            self.navigationItem.rightBarButtonItem = queueButton;
        }
    } else {
        if (self.navigationItem.rightBarButtonItem != nil) {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }
}

- (void)queueButtonPressed
{
    if (uploadQueueManager.inProgress) {
        [uploadQueueManager pauseQueue];
        [self.tableView setEditing:YES animated:YES];
    } else {
        [self.tableView setEditing:NO animated:YES];
        [uploadQueueManager startQueueIfNeeded];
    }
    [self setQueueButtonState];
}

- (void)refresh;
{
    [streamManager refresh];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[CacheManager sharedCacheManager] flushMemoryCache];
}

- (StreamPhoto *)streamPhotoAtIndexPath:(NSIndexPath*)indexPath {
    NSMutableArray *photos = streamManager.photos;
    if ([photos count] == 0) {
        return nil;
    }
    NSMutableArray *photoUploads = uploadQueueManager.photoUploads;
    if (indexPath.section < [photoUploads count]) {
        // upload cell
        return nil;
    }
    NSInteger photoIndex = indexPath.section - [photoUploads count];
    return [photos objectAtIndex:photoIndex];
}

- (PhotoUpload*)photoUploadAtIndexPath:(NSIndexPath*)indexPath;
{
    NSMutableArray *photoUploads = uploadQueueManager.photoUploads;
    if ([photoUploads count] == 0) {
        return nil;
    }
    if (indexPath.section < [photoUploads count]) {
        return [uploadQueueManager.photoUploads objectAtIndex:indexPath.section];
    }
    return nil;
}

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
    NSMutableArray *photos = self.streamManager.photos;
	NSInteger photosCount = photos.count == 0 ? 1 : photos.count;
    return photosCount + [uploadQueueManager.photoUploads count];
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PhotoUpload *upload = [self photoUploadAtIndexPath:indexPath];
    if (upload) {
        PhotoUploadCell *cell = [[PhotoUploadCell alloc] initWithPhotoUpload:upload];        
        return [cell autorelease];
    }
    
    StreamPhoto *photo = [self streamPhotoAtIndexPath:indexPath];
    if (photo) {
        StreamPhotoViewCell *cell = [self passiveTableCellForPhoto:photo];
        [cell loadImages];
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
        UITableViewCell *cell = [self passiveTableCellForPhoto:photo];
        return cell.frame.size.height + 10;
    }
    return 100;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    StreamPhoto *photo = [self streamPhotoAtIndexPath:indexPath];
    if (!photo) return;
    
    StreamPhotoViewController *vc = [[StreamPhotoViewController alloc] initWithPhoto:photo streamManager:self.streamManager];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];

}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;
{
    PhotoUpload *upload = [self photoUploadAtIndexPath:indexPath];
    if (upload) {
        return !uploadQueueManager.inProgress;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		[uploadQueueManager removePhotoUploadAtIndex:indexPath.section];
		//[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		// TOOD: use deleteRowsAtIndexPaths
		//[self.tableView reloadData];
    }   
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove";
}

# pragma mark memory management

- (void)dealloc {
    NSLog(@"deallocing %@", self.class);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.streamManager.delegate = nil;
    self.streamManager = nil;
    [queueButton release];
    [uploadQueueManager release];
    [super dealloc];
}


@end

