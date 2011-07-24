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
		
		//self.imageView.image = self.photoUpload.photo.thumbnailImage;
		
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
//		if ([self.photoUpload.state isEqualToString:PhotoUploadStatePending]) {
//			self.detailTextLabel.text = @"Queued for upload";
//		} else if ([self.photoUpload.state isEqualToString:PhotoUploadStateUploading]) {
//			self.detailTextLabel.text = [NSString stringWithFormat:@"Uploading (%@)", [percentFormatter stringFromNumber:self.photoUpload.progress]];
//		} else if ([self.photoUpload.state isEqualToString:PhotoUploadStateSettingTimestamp]) {
//			self.detailTextLabel.text = @"Setting timestamp";
//		} else if ([self.photoUpload.state isEqualToString:PhotoUploadStateSettingLocation]) {
//			self.detailTextLabel.text = @"Setting location";
//		} else if ([self.photoUpload.state isEqualToString:PhotoUploadStateSettingPermissions]) {
//			self.detailTextLabel.text = @"Setting permissions";
//		} else {
//			self.detailTextLabel.text = @"Finished uploading";
//		}
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
