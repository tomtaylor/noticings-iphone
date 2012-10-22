//
//  ImageViewController.h
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import <UIKit/UIKit.h>
#import "CacheManager.h"
#import "StreamPhoto.h"

@interface ImageViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate>

-(id)initWithPhoto:(StreamPhoto*)photo;

@property (strong) StreamPhoto *photo;
@property (strong) UIScrollView *scrollView;
@property (strong) UIImageView *imageView;

@end
