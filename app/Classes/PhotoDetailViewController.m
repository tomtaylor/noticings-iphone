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

@implementation PhotoDetailViewController

@synthesize photoUpload;
@synthesize photoTitleCell;
@synthesize photoTagsCell;
@synthesize privacyView;

- (id)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
		self.photoTitleCell = [[[EditableTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
															 reuseIdentifier:nil] autorelease];
		self.photoTitleCell.textField.delegate = self;
		self.photoTitleCell.textField.tag = PhotoTitle;
		self.photoTitleCell.textField.returnKeyType = UIReturnKeyNext;
		
		self.photoTagsCell = [[[EditableTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault 
														reuseIdentifier:nil] autorelease];
		self.photoTagsCell.textField.delegate = self;
		self.photoTagsCell.textField.tag = PhotoTags;
		self.photoTagsCell.textField.returnKeyType = UIReturnKeyNext;
		
		self.photoTagsCell.textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"defaultTags"];
		self.photoTagsCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.photoTagsCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        
        self.privacyView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 94.25)] autorelease];
        
        UILabel *privacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(19.0, 4.25, 320.0, 46.0)];
        privacyLabel.backgroundColor = [UIColor clearColor];
        privacyLabel.textColor = [UIColor colorWithRed:0.265 green:0.294 blue:0.367 alpha:1.0];
        
        privacyLabel.shadowColor = [UIColor whiteColor];
        privacyLabel.shadowOffset = CGSizeMake(0, 1);
        privacyLabel.font = [UIFont boldSystemFontOfSize:17.0];
        privacyLabel.text = @"Privacy";
        [privacyView addSubview:privacyLabel];
        [privacyLabel release];
        
        UISegmentedControl *privacyControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Private", @"F & F", @"Public", nil]];
        privacyControl.frame = CGRectMake(10, 50.25, 300, self.privacyView.frame.size.height-50.25);
        [privacyControl addTarget:self action:@selector(privacyChanged:) forControlEvents:UIControlEventValueChanged];
        [privacyControl setSelectedSegmentIndex:2]; // default to being public
        [privacyView addSubview:privacyControl];
        [privacyControl release];
        
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // If the user just pressed 'next' on the keyboard from the title cell, then jump to showing the tags cell. Otherwise, close the keyboard.
	if ([textField isEqual:self.photoTitleCell.textField]) {
		[self.photoTagsCell.textField becomeFirstResponder];
	} else {
        [textField resignFirstResponder];
        return NO;
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
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] 
                                     initWithTitle:@"Cancel" 
                                     style:UIBarButtonItemStylePlain 
                                     target:self 
                                     action:@selector(cancel)];
    [[self navigationItem] setLeftBarButtonItem:cancelButton];
    [cancelButton release];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateStyle:NSDateFormatterNoStyle];
	NSString *defaultTitle = [dateFormatter stringFromDate:[self.photoUpload timestamp]];
	[dateFormatter release];
	self.photoTitleCell.textField.placeholder = defaultTitle;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // don't focus keyboard, or it hides the privacy toggles.
    //[self.photoTitleCell.textField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.5];
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
    switch (section) {
        case TitleSection:
            return 2;
        case PrivacySection:
            return 0;
        default:
            return 0;
    }
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    switch (indexPath.section) {
		case TitleSection:
            switch (indexPath.row) {
                case 0:
                    return self.photoTitleCell;
                case 1:
                    return self.photoTagsCell;
            }
		default:
			return nil;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	switch (section) {
		case TitleSection: return @"Title & Tags";
        case PrivacySection: return @"Privacy";
	}
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	switch (section) {
		case TitleSection:
			return @"You can change the default tags in the Settings app.";
		default:
			return nil;
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    switch (section) {
        case PrivacySection:
            return self.privacyView;
        default:
            return nil;
    }
}

- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case PrivacySection:
            return self.privacyView.frame.size.height;
        default:
            return 46.0;
    }
}

#pragma mark Table View Delegate

- (void)next {
	self.photoUpload.title = self.photoTitleCell.textField.text; 
	self.photoUpload.tags = self.photoTagsCell.textField.text;
	
	if (self.photoUpload.timestamp == nil) {
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

- (void)cancel {
    [self.navigationController.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)privacyChanged:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.photoUpload.privacy = PhotoUploadPrivacyPrivate;
            break;
        case 1:
            self.photoUpload.privacy = PhotoUploadPrivacyFriendsAndFamily;
            break;
        case 2:
            self.photoUpload.privacy = PhotoUploadPrivacyPublic;
        default:
            break;
    }
}

@end

