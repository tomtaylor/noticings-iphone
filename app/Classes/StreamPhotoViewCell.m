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
    
    // layout for text above image
    CGFloat line1_top = PADDING_SIZE;
    CGFloat line2_top = line1_top + AVATAR_SIZE / 2;
    CGFloat line_height = AVATAR_SIZE / 2;
    CGFloat line_left = PADDING_SIZE + AVATAR_SIZE + PADDING_SIZE;
    CGFloat line_width = IMAGE_SIZE - (AVATAR_SIZE + PADDING_SIZE + TIMEBOX_SIZE);
    CGFloat timebox_left = bounds.size.width - (PADDING_SIZE + TIMEBOX_SIZE);

    CGFloat line3_top = PADDING_SIZE + AVATAR_SIZE + PADDING_SIZE + IMAGE_SIZE + PADDING_SIZE;
    
    
    
    CGRect avatarRect = CGRectMake(PADDING_SIZE, line1_top, AVATAR_SIZE, AVATAR_SIZE);
    avatarView = [[[RemoteImageView alloc] initWithFrame:avatarRect] autorelease];
    [[self contentView] addSubview:avatarView];
    
    CGRect imageRect = CGRectMake(PADDING_SIZE, PADDING_SIZE + AVATAR_SIZE + PADDING_SIZE, IMAGE_SIZE, IMAGE_SIZE);
    photoView = [[[RemoteImageView alloc] initWithFrame:imageRect] autorelease];
    [[self contentView] addSubview:photoView];
    
    
    // labels top-left
    usernameView = [self addLabelWithFrame:CGRectMake(line_left, line1_top, line_width, line_height)
                                  fontSize:HEADER_FONT_SIZE
                                      bold:YES
                                     color:[UIColor colorWithRed:0.1 green:0.4 blue:0.7 alpha:1]];
    
    placeView =    [self addLabelWithFrame:CGRectMake(line_left, line2_top, line_width, line_height)
                                  fontSize:HEADER_FONT_SIZE
                                      bold:YES
                                     color:[UIColor colorWithWhite:0.4 alpha:1]];
    
    

    
    // labels top-right
    visibilityView =  [self addLabelWithFrame:CGRectMake(timebox_left, line1_top, TIMEBOX_SIZE, line_height)
                                     fontSize:HEADER_FONT_SIZE
                                         bold:YES
                                        color:[UIColor colorWithWhite:0.6 alpha:1]];
    visibilityView.textAlignment = UITextAlignmentRight;

    timeagoView =  [self addLabelWithFrame:CGRectMake(timebox_left, line2_top, TIMEBOX_SIZE, line_height)
                                  fontSize:HEADER_FONT_SIZE
                                      bold:YES
                                     color:[UIColor colorWithWhite:0.6 alpha:1]];
    timeagoView.textAlignment = UITextAlignmentRight;
    
    
    
    
    // labels below image
    titleView =    [self addLabelWithFrame:CGRectMake(PADDING_SIZE, line3_top, IMAGE_SIZE, 100)
                                  fontSize:FONT_SIZE
                                      bold:YES
                                     color:[UIColor colorWithWhite:0.4 alpha:1]];
    
    descView =     [self addLabelWithFrame:CGRectMake(PADDING_SIZE, line3_top + 22, IMAGE_SIZE, 100)
                                  fontSize:FONT_SIZE
                                      bold:NO
                                     color:[UIColor colorWithWhite:0.4 alpha:1]];
    
    return self;
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
    CGFloat title = [StreamPhotoViewCell heightForString:photo.title font:[UIFont boldSystemFontOfSize:FONT_SIZE]];
    CGFloat description = 0.0f;
    if (photo.description.length) {
        description = PADDING_SIZE + [StreamPhotoViewCell heightForString:photo.description font:[UIFont systemFontOfSize:FONT_SIZE]];
    }
    return fixed + title + description + PADDING_SIZE;
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
    [avatarView loadURL:photo.avatarURL];
    
    CGFloat y = titleView.frame.origin.y;
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
