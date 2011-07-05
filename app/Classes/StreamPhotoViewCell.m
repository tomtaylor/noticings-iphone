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

@synthesize photoView;
@synthesize avatarView;
@synthesize usernameView;

-(id)initWithBounds:(CGRect)bounds;
{
    NSLog(@"Initting cell");
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"streamCell"];
    if (!self) return nil;
    
    float padding = 5;
    float avatarsize = 32;
    
    float imagesize = bounds.size.width - padding * 2;

    CGRect avatarRect = CGRectMake(padding, padding, avatarsize, avatarsize);
    self.avatarView = [[[RemoteImageView alloc] initWithFrame:avatarRect] autorelease];
    [[self contentView] addSubview:avatarView];

    CGRect imageRect = CGRectMake(padding, padding + avatarsize + padding, imagesize, imagesize);
    self.photoView = [[[RemoteImageView alloc] initWithFrame:imageRect] autorelease];
    [[self contentView] addSubview:photoView];
    
    CGRect usernameRect = CGRectMake(padding + avatarsize + padding, padding, imagesize, avatarsize);
    self.usernameView = [[[UITextView alloc] initWithFrame:usernameRect] autorelease];
    self.usernameView.text = @"";
    self.usernameView.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:usernameView];

    return self;
}

-(void) populateFromPhoto:(StreamPhoto*)photo;
{
    self.usernameView.text = photo.ownername;
    [self.photoView loadURL:photo.imageURL];
    [self.avatarView loadURL:photo.avatarURL];
}

- (void)dealloc {
    [super dealloc];
}


@end
