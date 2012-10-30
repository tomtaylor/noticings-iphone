//
//  EditableTextViewCell.m
//  Noticings
//
//  Created by Tom Taylor on 12/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EditableTextViewCell.h"


@implementation EditableTextViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CGRect bounds = [[self contentView] bounds];
		CGRect rect = CGRectInset(bounds, 20.0, 10.0);
		
		UITextView *textView = [[UITextView alloc] initWithFrame:rect];
		
		//  Set the keyboard's return key label to 'Next'.
		//
		[textView setReturnKeyType:UIReturnKeyDone];
		
		//  Make the clear button appear automatically.
		//[textView setClearButtonMode:UITextFieldViewModeWhileEditing];
		[textView setBackgroundColor:[UIColor whiteColor]];
		[textView setOpaque:YES];
		
		[[self contentView] addSubview:textView];
		[self setTextView:textView];
		
		[textView release];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:NO];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)dealloc {
    [super dealloc];
}


@end
