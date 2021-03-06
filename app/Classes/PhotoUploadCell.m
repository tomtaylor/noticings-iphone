//
//  PhotoUploadCell.m
//  Noticings
//
//  Created by Tom Taylor on 27/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoUploadCell.h"
#import "UploadQueueManager.h"
#import "NoticingsAppDelegate.h"

@implementation PhotoUploadCell

-(void)displayPhotoUpload:(PhotoUpload *)upload;
{
    if (self.photoUpload == upload) {
        return;
    }
    DLog(@"showing %@", upload);
    if (self.photoUpload) {
        [self.photoUpload removeObserver:self forKeyPath:@"inProgress"];
        [self.photoUpload removeObserver:self forKeyPath:@"uploadStatus"];
        [self.photoUpload removeObserver:self forKeyPath:@"progress"];
        [self.photoUpload removeObserver:self forKeyPath:@"paused"];
    }
    self.photoUpload = upload;
    
    if (self.photoUpload) {
        self.uploadImageView.image = self.photoUpload.thumbnail;
        
        if (self.photoUpload.title == nil || [self.photoUpload.title isEqualToString:@""]) {
            self.mainTextLabel.text = @"No title";
        } else {
            self.mainTextLabel.text = self.photoUpload.title;
        }
        
        self.progressView.progress = 0;
        
        [self updateDetailText];
        
        [self.photoUpload addObserver:self
                           forKeyPath:@"inProgress"
                              options:(NSKeyValueObservingOptionNew)
                              context:NULL];
        [self.photoUpload addObserver:self
                           forKeyPath:@"paused"
                              options:(NSKeyValueObservingOptionNew)
                              context:NULL];
        [self.photoUpload addObserver:self
                           forKeyPath:@"progress"
                              options:(NSKeyValueObservingOptionNew)
                              context:NULL];
        [self.photoUpload addObserver:self
                           forKeyPath:@"uploadStatus"
                              options:(NSKeyValueObservingOptionNew)
                              context:NULL];
        
    } else {
        self.uploadImageView.image = nil;
        self.mainTextLabel.text = @"";
        self.otherTextLabel.text = @"";
    }

}

- (void)updateDetailText {
    if (self.photoUpload.uploadStatus) {
        self.otherTextLabel.text = self.photoUpload.uploadStatus;
        self.otherTextLabel.hidden = NO;
        self.progressView.progress = [self.photoUpload.progress floatValue];
        self.progressView.hidden = YES;
        
    } else if (self.photoUpload.paused) {
            self.otherTextLabel.text = @"Upload paused";
            self.otherTextLabel.hidden = NO;
            self.progressView.progress = [self.photoUpload.progress floatValue];
            self.progressView.hidden = YES;
            
    } else if (self.photoUpload.inProgress) {
        self.otherTextLabel.text = @"invisible!";
        self.otherTextLabel.hidden = YES;
        self.progressView.progress = [self.photoUpload.progress floatValue];
        self.progressView.hidden = NO;
        
    } else {
        self.progressView.hidden = YES;
        self.otherTextLabel.hidden = NO;
        self.otherTextLabel.text = @"Queued";
    }
	[self setNeedsDisplay];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    // KVO isn't main-thread
    dispatch_async(dispatch_get_main_queue(),^{
        [self updateDetailText];
    });
}


- (void)dealloc {
    // do this to keep the watch removal in a single place
    [self displayPhotoUpload:nil];
}


@end
