//
//  PhotoUploadCell.m
//  Noticings
//
//  Created by Tom Taylor on 27/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoUploadCell.h"
#import "UploadQueueManager.h"

#import "StreamPhotoViewCell.h" // for PADDING constant
@interface PhotoUploadCell (Private)

- (void)updateDetailText;

@end


@implementation PhotoUploadCell

@synthesize photoUpload, imageView, textLabel, detailTextLabel, progressView;

-(id)init;
{
    self = [super init];
    if (self != nil) {
        [[UploadQueueManager sharedUploadQueueManager] addObserver:self
                                                        forKeyPath:@"inProgress"
                                                           options:(NSKeyValueObservingOptionNew)
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

        self.imageView.image = [UIImage imageWithCGImage:self.photoUpload.asset.thumbnail];
        
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
    
}

-(IBAction)pressedCancelButton;
{
    UIActionSheet *popupQuery = [[UIActionSheet alloc]
                                 initWithTitle:@"Cancel upload"
                                 delegate:self
                                 cancelButtonTitle:@"Continue"
                                 destructiveButtonTitle:@"Stop upload"
                                 otherButtonTitles:nil];
    [popupQuery showInView:self];
    [popupQuery release];
}
     
 -(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [[UploadQueueManager sharedUploadQueueManager] cancelUpload:self.photoUpload];
    }
}
     

- (void)updateDetailText {
	if ([UploadQueueManager sharedUploadQueueManager].inProgress) {
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
	[[UploadQueueManager sharedUploadQueueManager] removeObserver:self forKeyPath:@"inProgress"];
    [super dealloc];
}


@end
