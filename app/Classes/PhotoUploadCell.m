//
//  PhotoUploadCell.m
//  Noticings
//
//  Created by Tom Taylor on 27/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoUploadCell.h"
#import "UploadQueueManager.h"
#import <QuartzCore/QuartzCore.h>
#import "NoticingsAppDelegate.h"

#import "StreamPhotoViewCell.h" // for PADDING constant
@interface PhotoUploadCell (Private)

- (void)updateDetailText;

@end


@implementation PhotoUploadCell

@synthesize photoUpload, imageView, textLabel, detailTextLabel, progressView, optionsButton;
@synthesize topBorder, bottomBorder;

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [[NoticingsAppDelegate delegate].uploadQueueManager addObserver:self
                                                        forKeyPath:@"inProgress"
                                                           options:NSKeyValueObservingOptionNew
                                                           context:NULL];

    }
    return self;
}

-(void)displayPhotoUpload:(PhotoUpload *)_upload;
{
    if (self.photoUpload == _upload) {
        return;
    }

    if (self.photoUpload) {
        [self.photoUpload removeObserver:self forKeyPath:@"progress"];
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
                           forKeyPath:@"progress"
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

    UIColor *background = [UIColor colorWithWhite:0.8f alpha:1.0f];
    UIColor *shadow = [UIColor colorWithWhite:0.6f alpha:1.0f];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = topBorder.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[background CGColor], (id)[shadow CGColor], nil];
    [topBorder.layer insertSublayer:gradient atIndex:0];
    
    gradient = [CAGradientLayer layer];
    gradient.frame = bottomBorder.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[shadow CGColor], (id)[background CGColor], nil];
    [bottomBorder.layer insertSublayer:gradient atIndex:0];

    self.contentView.backgroundColor = background;

}

- (IBAction)pressedOptionsButton;
{
    UIActionSheet *popupQuery;
    
    if ([NoticingsAppDelegate delegate].uploadQueueManager.inProgress) {
        popupQuery = [[UIActionSheet alloc]
                      initWithTitle:@"Upload Options"
                      delegate:self
                      cancelButtonTitle:@"Cancel"
                      destructiveButtonTitle:@"Remove upload"
                      otherButtonTitles:@"Pause upload", nil];
    } else {
        popupQuery = [[UIActionSheet alloc]
                      initWithTitle:@"Upload Options"
                      delegate:self
                      cancelButtonTitle:@"Cancel"
                      destructiveButtonTitle:@"Remove upload"
                      otherButtonTitles:@"Retry upload", nil];

    }
    
    [popupQuery showInView:self];
    [popupQuery release];
}
     
 -(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UploadQueueManager *uploadQueueManager = [NoticingsAppDelegate delegate].uploadQueueManager;
    
    if (buttonIndex == 0) {
        [uploadQueueManager cancelUpload:self.photoUpload];
    } else if (buttonIndex == 1) {
        if (uploadQueueManager.inProgress) {
            [uploadQueueManager pauseQueue];
        } else {
//            [uploadQueueManager.photoUploads removeObject:self.photoUpload];
//            [uploadQueueManager.photoUploads insertObject:self.photoUpload atIndex:0];
//            [uploadQueueManager startQueueIfNeeded];
        }
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
