//
//  AddCommentViewController.m
//  Noticings
//
//  Created by Tom Insam on 07/10/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "AddCommentViewController.h"

@implementation AddCommentViewController
@synthesize photo, textView;

- (id)initWithPhoto:(StreamPhoto*)_photo;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.title = @"Add comment";
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textView = [[[UITextView alloc] initWithFrame:self.view.bounds] autorelease];
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.autoresizesSubviews = YES;
    [self.view addSubview:self.textView];

    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] 
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                     target:self
                                     action:@selector(saveComment)];
    
    self.navigationItem.rightBarButtonItem = saveButton;
    [saveButton release];

}

- (void)viewWillAppear:(BOOL)animated;
{
    [self.textView becomeFirstResponder];
}

-(void)saveComment;
{
    NSLog(@"Saving comment: %@", self.textView.text);
    
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

-(void)dealloc;
{
    self.photo = nil;
    self.textView = nil;
    [super dealloc];
}

@end
