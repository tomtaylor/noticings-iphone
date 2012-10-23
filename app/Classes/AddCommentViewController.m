//
//  AddCommentViewController.m
//  Noticings
//
//  Created by Tom Insam on 07/10/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import "AddCommentViewController.h"

#import"DeferredFlickrCallManager.h"
#import "NoticingsAppDelegate.h"

@implementation AddCommentViewController

- (id)initWithPhoto:(StreamPhoto*)photo;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.photo = photo;
        self.title = @"Add comment";
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.autoresizesSubviews = YES;
    
    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.textView];

    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] 
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                     target:self
                                     action:@selector(saveComment)];
    
    self.navigationItem.rightBarButtonItem = saveButton;

}

- (void)viewWillAppear:(BOOL)animated;
{
    [self.textView becomeFirstResponder];
}

-(void)saveComment;
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    NSLog(@"Saving comment on photo %@: %@", self.photo.flickrId, self.textView.text);
    
    NSString *method = @"flickr.photos.comments.addComment";
    NSDictionary *args = @{@"photo_id": self.photo.flickrId, @"comment_text": self.textView.text};

    [[NoticingsAppDelegate delegate].flickrCallManager
    callFlickrMethod:method
    asPost:YES
    withArgs:args
    andThen:^(NSDictionary* rsp){
        NSLog(@"comment addded!");
        [self.navigationController popViewControllerAnimated:YES];
    }
    orFail:^(NSString *code, NSString *error){
        NSLog(@"There was a problem sending the comment there. Try again later.");
        // TODO - popup. Do something better for feedback.
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
