//
//  StreamViewController.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullRefreshTableViewController.h"
#import "UploadQueueManager.h"
#import "PhotoStreamManager.h"
#import "StreamPhotoViewCell.h"

@interface StreamViewController : PullRefreshTableViewController {
    UIBarButtonItem *queueButton;
    UploadQueueManager *uploadQueueManager;
    IBOutlet StreamPhotoViewCell *photoViewCell;
    
}

-(id)initWithPhotoStreamManager:(PhotoStreamManager*)manager;
-(void)updatePullText;

@property (retain) PhotoStreamManager *streamManager;

@end
