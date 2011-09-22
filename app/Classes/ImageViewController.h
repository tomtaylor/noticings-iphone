//
//  ImageViewController.h
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CacheManager.h"
#import "StreamPhoto.h"

@interface ImageViewController : UIViewController <DeferredImageLoader, UIScrollViewDelegate>

-(void)displayPhoto:(StreamPhoto*)photo;
-(void)loadedImage:(UIImage *)image cached:(BOOL)cached;

@property (retain) StreamPhoto *photo;
@property (retain) UIScrollView *scrollView;
@property (retain) UIImageView *imageView;

@end
