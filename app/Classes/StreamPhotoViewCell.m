//
//  StreamPhotoViewCell.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamPhotoViewCell.h"

#import "FlickrAPIKeys.h"
#import "ObjectiveFlickr.h"

@implementation StreamPhotoViewCell

@synthesize imageView;
@synthesize avatarView;
@synthesize usernameView;

- (id)init;
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (!self) return nil;
    
    CGRect bounds = [[self contentView] bounds];
    
    float padding = 5;
    float avatarsize = 32;
    
    float imagesize = bounds.size.width - padding * 2;

    CGRect avatarRect = CGRectMake(padding, padding, avatarsize, avatarsize);
    self.avatarView = [[[UIImageView alloc] initWithFrame:avatarRect] autorelease];
    self.avatarView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    [[self contentView] addSubview:avatarView];

    CGRect imageRect = CGRectMake(padding, padding + avatarsize + padding, imagesize, imagesize);
    self.imageView = [[[UIImageView alloc] initWithFrame:imageRect] autorelease];
    self.imageView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];

    // TODO - http://stackoverflow.com/questions/603907/uiimage-resize-then-crop/605385#605385
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;

    [[self contentView] addSubview:imageView];
    
    CGRect usernameRect = CGRectMake(padding + avatarsize + padding, padding, imagesize, avatarsize);
    self.usernameView = [[[UITextView alloc] initWithFrame:usernameRect] autorelease];
    self.usernameView.text = @"username here";
    self.usernameView.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:usernameView];

    return self;
}

-(void) populateFromPhoto:(StreamPhoto*)photo;
{
    self.usernameView.text = photo.ownername;
    self.imageView.image = [UIImage imageWithData:photo.imageData];
    self.avatarView.image = [UIImage imageWithData:photo.avatarData];
}



- (void)dealloc {
    [super dealloc];
}


@end
