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

@synthesize photoUpload, imageView, textLabel, detailTextLabel, progressView, notAButton;

-(void)displayPhotoUpload:(PhotoUpload *)_upload;
{
    if (self.photoUpload == _upload) {
        return;
    }
    if (self.photoUpload) {
        [self.photoUpload removeObserver:self forKeyPath:@"inProgress"];
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
        
    } else {
        self.imageView.image = nil;
        self.textLabel.text = @"";
        self.detailTextLabel.text = @"";
    }

}

- (void)updateDetailText {
    if (self.photoUpload.inProgress) {
        self.detailTextLabel.text = @"";
        self.progressView.progress = [self.photoUpload.progress floatValue];
        self.progressView.hidden = NO;
        return;
    } else {
        self.progressView.hidden = YES;
        self.detailTextLabel.text = @"Queued";
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
    [super dealloc];
}


@end
