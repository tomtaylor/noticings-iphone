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

@synthesize photoUpload, imageView, textLabel, detailTextLabel, progressView;

-(void)displayPhotoUpload:(PhotoUpload *)_upload;
{
    if (self.photoUpload == _upload) {
        return;
    }
    if (self.photoUpload) {
        [self.photoUpload removeObserver:self forKeyPath:@"inProgress"];
        [self.photoUpload removeObserver:self forKeyPath:@"state"];
    }

    self.photoUpload = _upload;
    
    if (self.photoUpload) {

        if (self.photoUpload.asset) {
            self.imageView.image = [UIImage imageWithCGImage:self.photoUpload.asset.thumbnail];
        } else {
            self.imageView.image = [UIImage imageNamed:@"Icon"];
        }
        
        if (self.photoUpload.title == nil || [self.photoUpload.title isEqualToString:@""]) {
            self.textLabel.text = @"No title";
        } else {
            self.textLabel.text = self.photoUpload.title;
        }
        
        self.progressView.progress = 0;
        
        [self updateDetailText];
        
        [self.photoUpload addObserver:self
                           forKeyPath:@"inProgress"
                              options:(NSKeyValueObservingOptionNew)
                              context:NULL];
        
        [self.photoUpload addObserver:self
                           forKeyPath:@"state"
                              options:(NSKeyValueObservingOptionNew)
                              context:NULL];

    } else {
        self.imageView.image = nil;
        self.textLabel.text = @"";
        self.detailTextLabel.text = @"";
    }

}

- (void)updateDetailText {
	if ([NoticingsAppDelegate delegate].uploadQueueManager.inProgress) {
        if (!self.photoUpload.inProgress) {
            self.detailTextLabel.text = @"Queued";
            self.progressView.hidden = YES;
        } else {
            self.detailTextLabel.text = @"";
            self.progressView.progress = [self.photoUpload.progress floatValue];
            self.progressView.hidden = NO;
        }
	} else {
		self.detailTextLabel.text = @"Paused";
        self.progressView.hidden = YES;
	}
	
	[self setNeedsDisplay];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    [self updateDetailText];
}

- (void)dealloc {
    [self displayPhotoUpload:nil];
	[[NoticingsAppDelegate delegate].uploadQueueManager removeObserver:self forKeyPath:@"inProgress"];
    [super dealloc];
}


@end
