//
//  UploadTimestampViewController.h
//  Noticings
//
//  Created by Tom Taylor on 29/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoUpload.h"

@interface UploadTimestampViewController : UIViewController {
	PhotoUpload *photoUpload;
	IBOutlet UIDatePicker *datePicker;
}

@property (nonatomic, retain) PhotoUpload *photoUpload;
@property (nonatomic, retain) IBOutlet UIDatePicker *datePicker;

- (IBAction)datePickerChanged;

@end
