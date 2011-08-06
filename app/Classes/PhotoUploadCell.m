//
//  PhotoUploadCell.m
//  Noticings
//
//  Created by Tom Taylor on 27/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PhotoUploadCell.h"
#import "UploadQueueManager.h"

@interface PhotoUploadCell (Private)

- (void)updateDetailText;

@end


@implementation PhotoUploadCell

@synthesize photoUpload;

- (id)initWithPhotoUpload:(PhotoUpload *)_photoUpload
{
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
	if (self != nil) {		
		self.photoUpload = _photoUpload;
		
		self.imageView.image = [UIImage imageWithCGImage:self.photoUpload.asset.thumbnail];
		
		if (self.photoUpload.title == nil || [self.photoUpload.title isEqualToString:@""]) {
			self.textLabel.text = @"No title";
		} else {
			self.textLabel.text = self.photoUpload.title;
		}
        
		percentFormatter = [[NSNumberFormatter alloc] init];
		[percentFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[percentFormatter setPercentSymbol:@"%"];
		[percentFormatter setNumberStyle: NSNumberFormatterPercentStyle];
		[percentFormatter setDecimalSeparator:@"."];
		[percentFormatter setGeneratesDecimalNumbers:TRUE];
		[percentFormatter setMinimumFractionDigits:0];
		[percentFormatter setMaximumFractionDigits:0];
		[percentFormatter setRoundingMode: NSNumberFormatterRoundUp];
		[percentFormatter setRoundingIncrement:[NSNumber numberWithFloat:0.5]];
		
		[self updateDetailText];
		
		[self.photoUpload addObserver:self
						   forKeyPath:@"progress"
							  options:(NSKeyValueObservingOptionNew)
							  context:NULL];
		
		[self.photoUpload addObserver:self
						   forKeyPath:@"state"
							  options:(NSKeyValueObservingOptionNew)
							  context:NULL];
		
		[[UploadQueueManager sharedUploadQueueManager] addObserver:self
														forKeyPath:@"inProgress"
														   options:(NSKeyValueObservingOptionNew)
														   context:NULL];		
	}
	return self;
}

- (void) layoutSubviews {
	[super layoutSubviews];
	self.detailTextLabel.frame = CGRectMake(self.detailTextLabel.frame.origin.x, 
											self.detailTextLabel.frame.origin.y, 
											150.0f, 
											self.detailTextLabel.frame.size.height);
}

- (void)updateDetailText {
	if ([UploadQueueManager sharedUploadQueueManager].inProgress == YES) {
        
        if (!self.photoUpload.inProgress) {
            self.detailTextLabel.text = @"Queued for upload";
            return;
        }
        
        switch (self.photoUpload.state) {
            case PhotoUploadStatePendingUpload:
                self.detailTextLabel.text = [NSString stringWithFormat:@"Uploading (%@)", [percentFormatter stringFromNumber:self.photoUpload.progress]];
                break;
            case PhotoUploadStateUploaded:
                self.detailTextLabel.text = @"Setting metadata";
                break;
            case PhotoUploadStateLocationSet:
                self.detailTextLabel.text = @"Setting metadata";
                break;
            case PhotoUploadStateComplete:
                self.detailTextLabel.text = @"Uploaded successfully.";
                break;
            default:
                break;
        }        
	} else {
		self.detailTextLabel.text = @"Upload paused";
	}
	
	[self setNeedsDisplay];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	//if ([keyPath isEqual:@"progress"]) {
    [self updateDetailText];
	//}
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:NO];    
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)dealloc {
	[photoUpload removeObserver:self forKeyPath:@"progress"];
	[photoUpload removeObserver:self forKeyPath:@"state"];
	[[UploadQueueManager sharedUploadQueueManager] removeObserver:self forKeyPath:@"inProgress"];
	[photoUpload release];
	[percentFormatter release];
    [super dealloc];
}


@end
