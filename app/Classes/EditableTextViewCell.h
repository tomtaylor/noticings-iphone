//
//  EditableTextViewCell.h
//  Noticings
//
//  Created by Tom Taylor on 12/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EditableTextViewCell : UITableViewCell {
	UITextView *_textView;
}

@property (nonatomic, retain) UITextView *textView;

@end
