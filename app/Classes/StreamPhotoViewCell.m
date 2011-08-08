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

-(id)initWithBounds:(CGRect)bounds;
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"streamCell"];
    if (!self) return nil;

    CGFloat line3_top = IMAGE_WIDTH + PADDING_SIZE;
    
    CGRect imageRect = CGRectMake(PADDING_SIZE, 0, IMAGE_WIDTH, IMAGE_WIDTH);
    photoView = [[[RemoteImageView alloc] initWithFrame:imageRect] autorelease];
    [[self contentView] addSubview:photoView];
    
    // labels below image
    titleView =    [self addLabelWithFrame:CGRectMake(PADDING_SIZE, line3_top, IMAGE_WIDTH, 100)
                                  fontSize:FONT_SIZE
                                      bold:YES
                                     color:[UIColor colorWithWhite:0.4 alpha:1]];
    
    descView =     [self addLabelWithFrame:CGRectMake(PADDING_SIZE, line3_top + 22, IMAGE_WIDTH, 100)
                                  fontSize:FONT_SIZE
                                      bold:NO
                                     color:[UIColor colorWithWhite:0.4 alpha:1]];
    
    return self;
}


+(CGFloat) heightForString:(NSString*)string font:(UIFont*)font;
{
    CGSize constraint = CGSizeMake(IMAGE_WIDTH, 200000.0f);
    CGSize size = [string sizeWithFont:font
                     constrainedToSize:constraint
                         lineBreakMode:UILineBreakModeWordWrap];
    CGFloat height = MAX(size.height, 10.0f);
    return height;
}

+(CGFloat) cellHeightForPhoto:(StreamPhoto*)photo width:(CGFloat)width;
{
    CGFloat height = [photo imageHeightForWidth:width];

    CGFloat title = [StreamPhotoViewCell heightForString:photo.title font:[UIFont boldSystemFontOfSize:FONT_SIZE]];
    CGFloat description = 0.0f;
    if (photo.description.length) {
        description = PADDING_SIZE + [StreamPhotoViewCell heightForString:photo.description font:[UIFont systemFontOfSize:FONT_SIZE]];
    }
    return height // image
        + PADDING_SIZE // gap
        + title + description
        + 15; // just space out the rows a little
}



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

-(CGFloat)resizeLabel:(UILabel*)label atY:(CGFloat)y;
{
    CGFloat height = [StreamPhotoViewCell heightForString:label.text font:label.font];
    CGRect frame = label.frame;
    frame.size.height = height;
    frame.origin.y = y;
    label.frame = frame;
    return height;
}



-(void) populateFromPhoto:(StreamPhoto*)photo;
{
    usernameView.text = photo.ownername;
    // gfx are for losers. I like unicode.
    timeagoView.text = [@"⌚" stringByAppendingString:photo.ago];
    placeView.text = photo.placename;
    titleView.text = photo.title;
    descView.text = photo.description;
    int vis = photo.visibility;
    if (vis == StreamPhotoVisibilityPrivate) {
        visibilityView.text = @"private";
        visibilityView.textColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:1];
    } else if (vis == StreamPhotoVisibilityLimited) {
        visibilityView.text = @"limited";
        visibilityView.textColor = [UIColor colorWithRed:0.7 green:0.7 blue:0 alpha:1];
    } else if (vis == StreamPhotoVisibilityPublic) {
        visibilityView.text = @"public";
        visibilityView.textColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
    }

    [photoView loadURL:photo.imageURL];

    // resize image frame to have the right aspect.
    CGRect frame = photoView.frame;
    CGFloat height = [photo imageHeightForWidth:frame.size.width];
    frame.size.height = height;
    photoView.frame = frame;
    
    [avatarView loadURL:photo.avatarURL];
    
    CGFloat y = photoView.frame.origin.y + height + PADDING_SIZE;
    y += [self resizeLabel:titleView atY:y];
    [self resizeLabel:descView atY:y + PADDING_SIZE];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:NO];    
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)dealloc {
    [super dealloc];
}


@end
