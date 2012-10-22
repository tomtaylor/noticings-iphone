//
//  UploadTimestampViewController.m
//  Noticings
//
//  Created by Tom Taylor on 29/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "UploadTimestampViewController.h"
#import "PhotoMapViewController.h"

@implementation UploadTimestampViewController

@synthesize photoUpload;
@synthesize datePicker;

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Taken At";
	
	UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] 
								   initWithTitle:@"Next" 
								   style:UIBarButtonItemStylePlain
								   target:self
								   action:@selector(next)];
	
	[[self navigationItem] setRightBarButtonItem:nextButton];
	
	if (self.photoUpload.timestamp == nil) {
		[self.datePicker setDate:[NSDate date]];
	} else {
		[self.datePicker setDate:self.photoUpload.timestamp];		
	}
}

- (void)next {
	PhotoMapViewController *mapViewController = [[PhotoMapViewController alloc] init];
	mapViewController.photoUpload = self.photoUpload;
	[self.navigationController pushViewController:mapViewController animated:YES];
}

- (IBAction)datePickerChanged {
	self.photoUpload.timestamp = self.datePicker.date;
}




@end
