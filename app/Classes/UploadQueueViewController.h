//
//  UploadQueueViewController.h
//  Noticings
//
//  Created by Tom Taylor on 26/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UploadQueueManager.h"

@interface UploadQueueViewController : UITableViewController <UIImagePickerControllerDelegate> {
	UIBarButtonItem *queueButton;
}

@end