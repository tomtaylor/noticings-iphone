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
@synthesize timeagoView;
@synthesize placeView;

-(id)initWithBounds:(CGRect)bounds;
{
    NSLog(@"Initting cell");
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"streamCell"];
    if (!self) return nil;
    
    // these numbers arrived at by copying instagram. :-)
    float padding = 7;
    float avatarsize = 30;

    // width of the "time ago" box.
    float timesize = 70;
    
    float imagesize = bounds.size.width - padding * 2;

    CGRect avatarRect = CGRectMake(padding, padding, avatarsize, avatarsize);
    self.avatarView = [[[RemoteImageView alloc] initWithFrame:avatarRect] autorelease];
    [[self contentView] addSubview:avatarView];

    CGRect imageRect = CGRectMake(padding, padding + avatarsize + padding, imagesize, imagesize);
    self.photoView = [[[RemoteImageView alloc] initWithFrame:imageRect] autorelease];
    [[self contentView] addSubview:photoView];
    
    CGRect textRect = CGRectMake(padding + avatarsize, padding, imagesize - (avatarsize + padding + timesize), avatarsize);
    
    CGRect timeRect = CGRectMake(bounds.size.width - (padding + timesize), padding, timesize, avatarsize);
    
    self.usernameView = [[[UITextView alloc] initWithFrame:textRect] autorelease];
    self.usernameView.textAlignment = UITextAlignmentLeft;
    self.usernameView.font = [UIFont boldSystemFontOfSize:16];
    self.usernameView.contentMode = UIViewContentModeTopLeft;
    self.usernameView.textColor = [UIColor colorWithRed:0.1 green:0.5 blue:0.8 alpha:1];
    [self.contentView addSubview:usernameView];
    
    self.timeagoView = [[[UITextView alloc] initWithFrame:timeRect] autorelease];
    self.timeagoView.textAlignment = UITextAlignmentRight;
    self.timeagoView.font = [UIFont boldSystemFontOfSize:16];
    self.timeagoView.textColor = [UIColor colorWithWhite:0.6 alpha:1];
    self.timeagoView.contentMode = UIViewContentModeTopRight;
    [self.contentView addSubview:timeagoView];

//    self.placeView = [[[UITextView alloc] initWithFrame:textRect] autorelease];
//    self.placeView.contentMode = UIViewContentModeBottomLeft;
//    [self.contentView addSubview:placeView];
        
    return self;
}

-(void) populateFromPhoto:(StreamPhoto*)photo;
{
    self.usernameView.text = photo.ownername;
    self.timeagoView.text = photo.ago;
    self.placeView.text = photo.placename;
    [self.photoView loadURL:photo.imageURL];
    [self.avatarView loadURL:photo.avatarURL];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:NO];    
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)dealloc {
    [super dealloc];
}


@end
