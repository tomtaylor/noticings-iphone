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
    // This is a bit of a hack. The default indentation looks awful with an image in the cell, so we use indentation level to nudge the image right, but that also nudges the labels so there's an extra gap. So we have to adjust the labels back so they stay the same relative position from the image. Sigh.
    // We could do this by moving the contentview, but that seems to result in animation glitches.
    self.indentationWidth = 10.0f;
    
    if (self.editing) {
        self.indentationLevel = 1;
    } else {
        self.indentationLevel = 0;
    }
    
    [super layoutSubviews];
    
    if (self.indentationLevel > 0) {
        self.detailTextLabel.frame = CGRectOffset(self.detailTextLabel.frame, -self.indentationWidth, 0);
        self.textLabel.frame = CGRectOffset(self.textLabel.frame, -self.indentationWidth, 0);
    }
    
    // pad the uploading image to match the rest of the view.
    CGFloat height = self.frame.size.height;
    CGRect imageWithPadding = CGRectMake(PADDING_SIZE, PADDING_SIZE, height - PADDING_SIZE*2, height - PADDING_SIZE*2);
    self.imageView.bounds = imageWithPadding;
    self.imageView.frame = imageWithPadding;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)updateDetailText {
	if ([UploadQueueManager sharedUploadQueueManager].inProgress) {
        
        if (!self.photoUpload.inProgress) {
            self.detailTextLabel.text = @"Queued for upload";
            return;
        }
        
        self.detailTextLabel.text = [NSString stringWithFormat:@"Uploading (%@)", [percentFormatter stringFromNumber:self.photoUpload.progress]];
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
