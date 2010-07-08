//
//  PhotoDetailViewController.h
//  Noticings
//
//  Created by Tom Taylor on 11/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhotoUpload;
@class EditableTextFieldCell;

// Photo fields

enum {
    PhotoTitle,
    PhotoTags
};

// Table sections

enum {
    TitleSection,
    TagsSection
};

@interface PhotoDetailViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate> {
	PhotoUpload *photoUpload;
	EditableTextFieldCell *photoTitleCell;
	EditableTextFieldCell *photoTagsCell;
}

@property (nonatomic, retain) PhotoUpload *photoUpload;
@property (nonatomic, retain) EditableTextFieldCell *photoTitleCell;
@property (nonatomic, retain) EditableTextFieldCell *photoTagsCell;

- (void)next;

@end
