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

@interface StreamViewController (Private)

- (void)setQueueButtonState;
- (void)queueButtonPressed;

@end

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(uploadQueueDidChange) 
												 name:@"queueCount" 
											   object:nil];
    
    uploadQueueManager = [UploadQueueManager sharedUploadQueueManager];
    
    [uploadQueueManager addObserver:self
                         forKeyPath:@"inProgress"
                            options:(NSKeyValueObservingOptionNew)
                            context:NULL];
	
    queueButton = [[UIBarButtonItem alloc] 
                   initWithTitle:@"Pause Queue" 
                   style:UIBarButtonItemStylePlain 
                   target:self
                   action:@selector(queueButtonPressed)];
    
    [self setQueueButtonState];

    [[StreamManager sharedStreamManager] maybeRefresh];
}

- (void)newPhotos;
{
	[self.tableView reloadData];
    [self stopLoading];
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
    NSMutableArray *photoUploads = uploadQueueManager.photoUploads;
    
    if (indexPath.row+1 > [photoUploads count]) {
        NSInteger photoIndex = indexPath.row - [photoUploads count];
        StreamPhoto *photo = [photos objectAtIndex:photoIndex];
        NSLog(@"page url is %@", photo.pageURL);
        [[UIApplication sharedApplication] openURL:photo.pageURL];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row < [uploadQueueManager.photoUploads count]) {
        return !uploadQueueManager.inProgress;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		[uploadQueueManager removePhotoUploadAtIndex:indexPath.row];
		//[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		// TOOD: use deleteRowsAtIndexPaths
		//[self.tableView reloadData];
    }   
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove";
}

# pragma mark memory management

- (void)dealloc {
    [super dealloc];
}


@end

