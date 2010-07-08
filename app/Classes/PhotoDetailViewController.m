//
//  PhotoDetailViewController.m
//  Noticings
//
//  Created by Tom Taylor on 11/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoDetailViewController.h"
#import "EditableTextFieldCell.h"
#import "PhotoMapViewController.h"
#import "UploadTimestampViewController.h"
#import "Photo.h"

@implementation PhotoDetailViewController

@synthesize photoUpload;
@synthesize photoTitleCell;
@synthesize photoTagsCell;

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {

		self.photoTitleCell = [[EditableTextFieldCell alloc] initWithFrame:CGRectZero 
															 reuseIdentifier:nil];
		self.photoTitleCell.textField.delegate = self;
		self.photoTitleCell.textField.tag = PhotoTitle;
		self.photoTitleCell.textField.returnKeyType = UIReturnKeyNext;
		
		self.photoTagsCell = [[EditableTextFieldCell alloc] initWithFrame:CGRectZero 
														reuseIdentifier:nil];
		self.photoTagsCell.textField.delegate = self;
		self.photoTagsCell.textField.tag = PhotoTags;
		self.photoTagsCell.textField.returnKeyType = UIReturnKeyNext;
		
		self.photoTagsCell.textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"defaultTags"];
		self.photoTagsCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.photoTagsCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if ([textField isEqual:self.photoTitleCell.textField]) {
		[self.photoTagsCell.textField becomeFirstResponder];
	} else {
		[self next];
	}
	return YES;
}


- (void)dealloc {
	[photoUpload release];
	[photoTitleCell release];
	[photoTagsCell release];
    [super dealloc];
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Details";
	
	UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] 
								   initWithTitle:@"Next" 
								   style:UIBarButtonItemStylePlain
								   target:self
								   action:@selector(next)];
	
	[[self navigationItem] setRightBarButtonItem:nextButton];
	[nextButton release];
	
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateStyle:NSDateFormatterNoStyle];
	NSString *defaultTitle = [dateFormatter stringFromDate:self.photoUpload.photo.timestamp];
	[dateFormatter release];
	self.photoTitleCell.textField.placeholder = defaultTitle;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	[self.photoTitleCell.textField becomeFirstResponder];
}

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


#pragma mark Table datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSUInteger section = [indexPath section];
    
    switch (section) {
		case TitleSection:
			return self.photoTitleCell;
			break;
		case TagsSection:
			return self.photoTagsCell;
			break;
		default:
			return nil;
			break;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	switch (section) {
		case TitleSection: return @"Title";
		case TagsSection: return @"Tags";
	}

	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	switch (section) {
		case TagsSection:
			return @"You can change the default tags in your device settings.";
			break;
		default:
			return nil;
			break;
	}
}

#pragma mark Table View Delegate

- (void)next {
	self.photoUpload.title = self.photoTitleCell.textField.text; 
	self.photoUpload.tags = self.photoTagsCell.textField.text;
	
	if (self.photoUpload.photo.timestamp == nil) {
		UploadTimestampViewController *timestampViewController = [[UploadTimestampViewController alloc] init];
		timestampViewController.photoUpload = self.photoUpload;
		[self.navigationController pushViewController:timestampViewController animated:YES];
		[timestampViewController release];
	} else {
		PhotoMapViewController *mapViewController = [[PhotoMapViewController alloc] init];
		mapViewController.photoUpload = self.photoUpload;
		[self.navigationController pushViewController:mapViewController animated:YES];
		[mapViewController release];
	}
}

@end

