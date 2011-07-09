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
@synthesize titleView;
@synthesize descView;

#define TITLE_FONT_SIZE 14

-(UILabel*) addLabelWithFrame:(CGRect)frame fontSize:(int)size bold:(BOOL)bold color:(UIColor*)color;
{
    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    label.textAlignment = UITextAlignmentLeft;
    if (bold) {
        label.font = [UIFont boldSystemFontOfSize:size];
    } else {
        label.font = [UIFont systemFontOfSize:size];
    }
    label.contentMode = UIViewContentModeTopLeft;
    label.textColor = color;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.minimumFontSize = size;
    label.numberOfLines = 0;

    [self.contentView addSubview:label];
    [label release];
    return label;
}

+(CGFloat) heightForString:(NSString*)string font:(UIFont*)font;
{
    CGSize constraint = CGSizeMake(IMAGE_SIZE, 200000.0f);
    CGSize size = [string sizeWithFont:font
                     constrainedToSize:constraint
                         lineBreakMode:UILineBreakModeWordWrap];
    CGFloat height = MAX(size.height, 10.0f);
    return height;
}

+(CGFloat) cellHeightForPhoto:(StreamPhoto*)photo;
{
    CGFloat fixed = PADDING_SIZE + AVATAR_SIZE + PADDING_SIZE + IMAGE_SIZE + PADDING_SIZE;
    CGFloat title = [StreamPhotoViewCell heightForString:photo.title font:[UIFont boldSystemFontOfSize:TITLE_FONT_SIZE]];
    CGFloat description = 0.0f;
    if (photo.description.length) {
        description = PADDING_SIZE + [StreamPhotoViewCell heightForString:photo.description font:[UIFont systemFontOfSize:TITLE_FONT_SIZE]];
    }
    return fixed + title + description + PADDING_SIZE;
}

-(id)initWithBounds:(CGRect)bounds;
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"streamCell"];
    if (!self) return nil;
    
    CGRect avatarRect = CGRectMake(PADDING_SIZE, PADDING_SIZE, AVATAR_SIZE, AVATAR_SIZE);
    self.avatarView = [[[RemoteImageView alloc] initWithFrame:avatarRect] autorelease];
    [[self contentView] addSubview:avatarView];

    CGRect imageRect = CGRectMake(PADDING_SIZE, PADDING_SIZE + AVATAR_SIZE + PADDING_SIZE, IMAGE_SIZE, IMAGE_SIZE);
    self.photoView = [[[RemoteImageView alloc] initWithFrame:imageRect] autorelease];
    [[self contentView] addSubview:photoView];
    

    CGRect textRect = CGRectMake(PADDING_SIZE + AVATAR_SIZE, PADDING_SIZE, IMAGE_SIZE - (AVATAR_SIZE + PADDING_SIZE + TIMEBOX_SIZE), AVATAR_SIZE);
    self.usernameView = [self addLabelWithFrame:textRect
                                       fontSize:16
                                           bold:YES
                                          color:[UIColor colorWithRed:0.1 green:0.4 blue:0.7 alpha:1]];
    

    CGRect timeRect = CGRectMake(bounds.size.width - (PADDING_SIZE + TIMEBOX_SIZE), PADDING_SIZE, TIMEBOX_SIZE, AVATAR_SIZE);
    self.timeagoView =  [self addLabelWithFrame:timeRect
                                       fontSize:16
                                           bold:YES
                                          color:[UIColor colorWithWhite:0.6 alpha:1]];
    self.timeagoView.textAlignment = UITextAlignmentRight;

    
    CGRect titleRect = CGRectMake(PADDING_SIZE, PADDING_SIZE + AVATAR_SIZE + PADDING_SIZE + IMAGE_SIZE + PADDING_SIZE, IMAGE_SIZE, 100);
    self.titleView =    [self addLabelWithFrame:titleRect
                                       fontSize:TITLE_FONT_SIZE
                                           bold:YES
                                          color:[UIColor colorWithWhite:0.4 alpha:1]];
    
    CGRect descRect = CGRectMake(PADDING_SIZE, PADDING_SIZE + AVATAR_SIZE + PADDING_SIZE + IMAGE_SIZE + PADDING_SIZE + PADDING_SIZE, IMAGE_SIZE, 100);
    self.descView =     [self addLabelWithFrame:descRect
                                       fontSize:TITLE_FONT_SIZE
                                           bold:NO
                                          color:[UIColor colorWithWhite:0.4 alpha:1]];
    
    return self;
}

-(CGFloat)resizeLabel:(UILabel*)label atY:(CGFloat)y;
{
    CGFloat height = [StreamPhotoViewCell heightForString:label.text font:label.font];
    CGRect frame = label.frame;
    NSLog(@"setting heigt for frame to %f", height);
    frame.size.height = height;
    frame.origin.y = y;
    label.frame = frame;
    return height;
}

-(void) populateFromPhoto:(StreamPhoto*)photo;
{
    self.usernameView.text = photo.ownername;
    self.timeagoView.text = photo.ago;
    self.placeView.text = photo.placename;
    self.titleView.text = photo.title;
    self.descView.text = photo.description;

    [self.photoView loadURL:photo.imageURL];
    [self.avatarView loadURL:photo.avatarURL];
    
    CGFloat y = self.titleView.frame.origin.y;
    
    CGFloat height = [self resizeLabel:self.titleView atY:y];
    [self resizeLabel:self.descView atY:y + height + PADDING_SIZE];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:NO];    
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)dealloc {
    [super dealloc];
}


@end
