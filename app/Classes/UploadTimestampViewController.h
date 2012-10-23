//
//  UploadTimestampViewController.h
//  Noticings
//
//  Created by Tom Taylor on 29/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoUpload.h"

@interface UploadTimestampViewController : UIViewController

@property (nonatomic, strong) PhotoUpload *photoUpload;
@property (nonatomic, strong) IBOutlet UIDatePicker *datePicker;

- (IBAction)datePickerChanged;

@end
