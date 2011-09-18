//
//  UploadQueueViewController.m
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "UploadQueueViewController.h"
#import "UploadQueueManager.h"
#import "PhotoUpload.h"
#import "PhotoUploadCell.h"
#import "PhotoDetailViewController.h"

@interface UploadQueueViewController (Private)

- (void)updateQueueButton;

@end


@implementation UploadQueueViewController


- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(queueDidChange) 
												 name:@"queueCount" 
											   object:nil];
	
	[[UploadQueueManager sharedUploadQueueManager] addObserver:self
													forKeyPath:@"inProgress"
													   options:(NSKeyValueObservingOptionNew)
													   context:NULL];
	
	queueButton = [[UIBarButtonItem alloc] 
				   initWithTitle:@"Pause"
				   style:UIBarButtonItemStylePlain
				   target:self
				   action:@selector(queueButtonPressed)];
	
	[[self navigationItem] setLeftBarButtonItem:queueButton];
	
	[self updateQueueButton];
}

- (void)queueButtonPressed {
	if ([UploadQueueManager sharedUploadQueueManager].inProgress == YES) {
		[[UploadQueueManager sharedUploadQueueManager] pauseQueue];
	} else {
		[[UploadQueueManager sharedUploadQueueManager] startQueueIfNeeded];
	}
}

- (void)updateQueueButton {
	int count = [[UploadQueueManager sharedUploadQueueManager].photoUploads count];
	
	if (count > 0) {
		if (self.navigationItem.leftBarButtonItem == nil)
			self.navigationItem.leftBarButtonItem = queueButton;
		
		if ([UploadQueueManager sharedUploadQueueManager].inProgress == YES) {
			//queueButton.enabled = YES;
			queueButton.title = @"Pause";
		} else {
			//queueButton.enabled = YES;
			queueButton.title = @"Start";
		}
	} else {
		queueButton.title = @"Pause";
		self.navigationItem.leftBarButtonItem = nil;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	NSLog(@"Queue process changed");
	[self updateQueueButton];
	//[self.tableView reloadData];
}


- (void)queueDidChange {
	[self.tableView reloadData];
	[self updateQueueButton];
}

//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//	//[self presentModalViewController:imagePicker animated:YES];
//}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"queueCount" object:nil];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	int count = [[UploadQueueManager sharedUploadQueueManager].photoUploads count];
	
	if (count == 0) {
		return 1;
	} else {
		return count;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if ([[UploadQueueManager sharedUploadQueueManager].photoUploads count] == 0) {
		UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.textLabel.text = @"There aren't any photos queued for upload";
		cell.textLabel.textColor = [UIColor grayColor];
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	} else {
		PhotoUpload *photoUpload = [[UploadQueueManager sharedUploadQueueManager].photoUploads objectAtIndex:indexPath.row];
		PhotoUploadCell *cell = [[[PhotoUploadCell alloc] initWithPhotoUpload:photoUpload] autorelease];
		return cell;
	}
	
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return [UploadQueueManager sharedUploadQueueManager].inProgress == NO;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		[[UploadQueueManager sharedUploadQueueManager] removePhotoUploadAtIndex:indexPath.row];
		
		// TOOD: use deleteRowsAtIndexPaths
		[self.tableView reloadData];
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 75.0f;
}

- (void)dealloc {
	[queueButton release];
    [super dealloc];
}


@end

