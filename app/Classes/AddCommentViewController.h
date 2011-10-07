//
//  AddCommentViewController.h
//  Noticings
//
//  Created by Tom Insam on 07/10/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StreamPhoto.h"

@interface AddCommentViewController : UIViewController

- (id)initWithPhoto:(StreamPhoto*)_photo;

@property (retain) StreamPhoto* photo;
@property (retain) UITextView *textView;
@end
