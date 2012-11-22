//
//  PhotoDetailViewController.h
//  Noticings
//
//  Created by Tom Taylor on 11/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

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

@interface PhotoDetailViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) PhotoUpload *photoUpload;
@property (nonatomic, strong) IBOutlet UITextField *photoTitle;
@property (nonatomic, strong) IBOutlet UITextField *photoTags;
@property (nonatomic, strong) IBOutlet UIView *privacyView;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, strong) IBOutlet UILabel *detailText;

@property (nonatomic, strong) NSString *defaultTitle;

-(id)initWithPhotoUpload:(PhotoUpload*)upload;
- (IBAction)privacyChanged:(UISegmentedControl *)sender;

@end
