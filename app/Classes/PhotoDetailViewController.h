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
    PrivacySection
};

@interface PhotoDetailViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) PhotoUpload *photoUpload;
@property (nonatomic, strong) EditableTextFieldCell *photoTitleCell;
@property (nonatomic, strong) EditableTextFieldCell *photoTagsCell;
@property (nonatomic, strong) UIView *privacyView;

- (void)next;

@end
