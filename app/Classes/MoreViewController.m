//
//  MoreViewController.m
//  Noticings
//
//  Created by Tom Taylor on 31/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MoreViewController.h"
#import "FlickrAuthenticationViewController.h"

enum Sections {
	kNoticingsSection = 0,
	kFlickrSection,
	kAppSection,
	NUM_SECTIONS
};

enum NoticingsSectionRows {
	kNoticingsSectionSiteRow,
	NUM_NOTICINGS_SECTION_ROWS
};

enum FlickrSectionRows {
	kFlickrSectionSiteRow = 0,
	NUM_FLICKR_SECTION_ROWS
};

enum AppSectionRows {
	kAppSectionSignoutRow = 0,
	NUM_APP_SECTION_ROWS
};


@implementation MoreViewController


- (void)viewDidLoad {
    if (!cameraController) {
        cameraController = [[CameraController alloc] initWithBaseViewController:self];
    }
    [super viewDidLoad];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
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
    if (cameraController) {
        [cameraController release];
        cameraController = nil;
    }    
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_SECTIONS;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
		case kNoticingsSection:
			return NUM_NOTICINGS_SECTION_ROWS;
		case kFlickrSection:
			return NUM_FLICKR_SECTION_ROWS;
		case kAppSection:
			return NUM_APP_SECTION_ROWS;
		default:
			return 1;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	
	if (indexPath.section == kNoticingsSection) {
		switch (indexPath.row) {
			case kNoticingsSectionSiteRow:
				cell.textLabel.text = @"Upload from Camera Roll";
				break;
			default:
				break;
		}
	} else if (indexPath.section == kFlickrSection) {
		cell.textLabel.text = @"Open flickr.com";
	} else {
		cell.textLabel.text = @"Sign out";
	}
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == kNoticingsSection) {
		switch (indexPath.row) {
			case kNoticingsSectionSiteRow:
				[cameraController presentImagePicker];
				break;
			default:
				break;
		}
	} else if (indexPath.section == kFlickrSection) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://m.flickr.com"]];
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"authToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
		FlickrAuthenticationViewController *authViewController = [[FlickrAuthenticationViewController alloc] init];
		[authViewController displaySignIn];
		[self presentModalViewController:authViewController animated:YES];
		[authViewController release];
	}

}

- (void)dealloc {
    [cameraController release];
    [super dealloc];
}


@end

