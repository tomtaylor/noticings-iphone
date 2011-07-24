//
//  PhotoPreviewViewController.h
//  Noticings
//
//  Created by Tom Taylor on 05/05/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PhotoPreviewViewController : UIViewController {
    IBOutlet UIImageView *imageView;
    UIBarButtonItem *nextButton;
}

@property (nonatomic, retain) IBOutlet UIImageView *imageView;

@end
