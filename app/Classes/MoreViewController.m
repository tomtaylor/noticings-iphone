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

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
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
				cell.textLabel.text = @"Open noticin.gs";
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
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://noticin.gs"]];
				break;
			default:
				break;
		}
	} else if (indexPath.section == kFlickrSection) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://m.flickr.com"]];
	} else {
		//[[NSUserDefaults standardUserDefaults] setNilValueForKey:@"authToken"];
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"authToken"];
		//[[NSUserDefaults standardUserDefaults] setNilValueForKey:@"userName"];
		FlickrAuthenticationViewController *authViewController = [[FlickrAuthenticationViewController alloc] init];
		[authViewController displaySignIn];
		[self presentModalViewController:authViewController animated:YES];
		[authViewController release];
	}

}

- (void)dealloc {
    [super dealloc];
}


@end

