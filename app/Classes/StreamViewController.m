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

@implementation StreamViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(newPhotos) 
												 name:@"newPhotos" 
											   object:nil];
	
    [[StreamManager sharedStreamManager] addObserver:self
                                          forKeyPath:@"inProgress"
                                             options:(NSKeyValueObservingOptionNew)
                                             context:NULL];

    
    refreshButton = [[UIBarButtonItem alloc] 
                     initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                          target:self
                                          action:@selector(refreshButtonPressed)];
	
	[[self navigationItem] setRightBarButtonItem:refreshButton];
    [refreshButton release];
    
    [self performSelector:@selector(refreshButtonPressed) withObject:nil afterDelay:0.1];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	NSLog(@"manager process changed");
    refreshButton.enabled = !( [StreamManager sharedStreamManager].inProgress );
}

- (void)newPhotos;
{
	[self.tableView reloadData];
}

- (void)refreshButtonPressed;
{
    [[StreamManager sharedStreamManager] refresh];
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
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
	if (photos.count == 0) {
        return 1;
    }
    return photos.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSMutableArray *photos = [StreamManager sharedStreamManager].photos;
    
	if (photos.count == 0) {
		UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:nil] autorelease];
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.textLabel.text = @"No photos from your contacts";
		cell.textLabel.textColor = [UIColor grayColor];
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;

	} else {
        StreamPhotoViewCell *cell = (StreamPhotoViewCell*)[tableView dequeueReusableCellWithIdentifier:@"streamCell"];
        if (cell == nil) {
            CGRect bounds = self.view.bounds;
            cell = [[[StreamPhotoViewCell alloc] initWithBounds:bounds] autorelease];
        } 
        
        StreamPhoto *photo = [photos objectAtIndex:indexPath.row];
        [cell populateFromPhoto:photo];
        
        return cell;
	}
	
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 400.0f;
}

- (void)dealloc {
    [super dealloc];
}


@end

