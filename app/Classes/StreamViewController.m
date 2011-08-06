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
#import "StreamManager.h"
#import "PhotoUploadCell.h"

@implementation StreamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textPull = @"Pull to refresh..";
    self.textRelease = @"Release to refresh..";
    self.textLoading = @"Loading..";

	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(newPhotos) 
												 name:@"newPhotos" 
											   object:nil];
	
    [[StreamManager sharedStreamManager] addObserver:self
                                          forKeyPath:@"inProgress"
                                             options:(NSKeyValueObservingOptionNew)
                                             context:NULL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(uploadQueueDidChange) 
												 name:@"queueCount" 
											   object:nil];
    
    
    refreshButton = [[UIBarButtonItem alloc] 
                     initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                          target:self
                                          action:@selector(refreshButtonPressed)];
    
    uploadQueueManager = [UploadQueueManager sharedUploadQueueManager];
	
	[[self navigationItem] setRightBarButtonItem:refreshButton];
    [refreshButton release];

    [[StreamManager sharedStreamManager] maybeRefresh];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    refreshButton.enabled = !( [StreamManager sharedStreamManager].inProgress );
    //refreshButton.style = refreshButton.enabled ? UIBarButtonSystemItemRefresh : UIBarButtonSystemItemStop;
    if (refreshButton.enabled) {
        [self stopLoading];
    }
}

- (void)newPhotos;
{
	[self.tableView reloadData];
    [self stopLoading];
}

- (void)uploadQueueDidChange
{
    [self.tableView reloadData];
}

- (void)refresh;
{
    [[StreamManager sharedStreamManager] refresh];
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
    [[StreamManager sharedStreamManager] flushMemoryCache];
}

- (void)viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSMutableArray *photos = [StreamManager sharedStreamManager].photos;
	NSInteger photosCount = photos.count == 0 ? 1 : photos.count;
    return photosCount + [uploadQueueManager.photoUploads count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSMutableArray *photos = [StreamManager sharedStreamManager].photos;
    NSMutableArray *photoUploads = uploadQueueManager.photoUploads;
    
    if (indexPath.row+1 > [photoUploads count]) {
        if (photos.count == 0) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:nil];
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.textLabel.text = @"No photos from your contacts";
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.font = [UIFont systemFontOfSize:14];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return [cell autorelease];
            
        } else {
            // TODO - reuse identifier removed for now because of deferred loading bugs. Needs to come back at some point.
            StreamPhotoViewCell *cell = (StreamPhotoViewCell*)[tableView dequeueReusableCellWithIdentifier:nil];
            if (cell == nil) {
                CGRect bounds = self.view.bounds;
                cell = [[[StreamPhotoViewCell alloc] initWithBounds:bounds] autorelease];
            } 
            
            NSInteger photoIndex = indexPath.row - [photoUploads count];
            StreamPhoto *photo = [photos objectAtIndex:photoIndex];
            [cell populateFromPhoto:photo];
            
            return cell;
        }
    } else {
        PhotoUpload *photoUpload = [uploadQueueManager.photoUploads objectAtIndex:indexPath.row];
        PhotoUploadCell *cell = [[PhotoUploadCell alloc] initWithPhotoUpload:photoUpload];        
        return [cell autorelease];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *photos = [StreamManager sharedStreamManager].photos;
    NSMutableArray *photoUploads = uploadQueueManager.photoUploads;
    
    if (indexPath.row+1 > [photoUploads count]) {    
        if (photos.count == 0) {
            return 100.0f;
        }
        
        NSInteger photoIndex = indexPath.row - [photoUploads count];
        StreamPhoto *photo = [photos objectAtIndex:photoIndex];
        return [StreamPhotoViewCell cellHeightForPhoto:photo];
    } else {
        return 75.0f;
    }
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSMutableArray *photos = [StreamManager sharedStreamManager].photos;
    StreamPhoto *photo = [photos objectAtIndex:indexPath.row];
    NSLog(@"page url is %@", photo.pageURL);
    [[UIApplication sharedApplication] openURL:photo.pageURL];
}



# pragma mark memory management

- (void)dealloc {
    [super dealloc];
}


@end

