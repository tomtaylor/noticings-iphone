//
//  StreamViewController.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamViewController.h"
#import "StreamPhotoViewCell.h"
#import "StreamPhoto.h"
#import "ContactsStreamManager.h"
#import "CacheManager.h"
#import "PhotoUploadCell.h"

@interface StreamViewController (Private)

- (void)setQueueButtonState;
- (void)queueButtonPressed;

@end

@implementation StreamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textPull = @"Pull to refresh..";
    self.textRelease = @"Release to refresh..";
    self.textLoading = @"Loading..";

	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(newPhotos) 
												 name:@"newPhotos" 
											   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(uploadQueueDidChange) 
												 name:@"queueCount" 
											   object:nil];
    
    if (uploadQueueManager == nil) {
        uploadQueueManager = [UploadQueueManager sharedUploadQueueManager];
    }
        
    [uploadQueueManager addObserver:self
                         forKeyPath:@"inProgress"
                            options:(NSKeyValueObservingOptionNew)
                            context:NULL];
	
    if (queueButton == nil) {
        queueButton = [[UIBarButtonItem alloc] 
                       initWithTitle:@"Pause Queue" 
                       style:UIBarButtonItemStylePlain 
                       target:self
                       action:@selector(queueButtonPressed)];
    }
    
    [self setQueueButtonState];

    self.tableView.sectionHeaderHeight = PADDING_SIZE + AVATAR_SIZE + PADDING_SIZE;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [[ContactsStreamManager sharedContactsStreamManager] maybeRefresh];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // we need to unsubscribe, in case they fire and it no longer exists
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // tear this down too - it'll be reassigned and subscribed when viewDidLoad is called again
    if (uploadQueueManager) {
        [uploadQueueManager removeObserver:self forKeyPath:@"inProgress"];
        [uploadQueueManager release];
        uploadQueueManager = nil;
    }
    
}

- (void)newPhotos;
{
	[self.tableView reloadData];
    [self stopLoading];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	[self setQueueButtonState];
}

- (void)uploadQueueDidChange
{
    [self setQueueButtonState];
    [self.tableView reloadData];
}

- (void)setQueueButtonState
{
    if ([uploadQueueManager.photoUploads count] > 0) {
        if (uploadQueueManager.inProgress) {
            queueButton.title = @"Pause Queue";
        } else {
            queueButton.title = @"Start Queue";
        }
        if (self.navigationItem.rightBarButtonItem == nil) {
            self.navigationItem.rightBarButtonItem = queueButton;
        }
    } else {
        if (self.navigationItem.rightBarButtonItem != nil) {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }
}

- (void)queueButtonPressed
{
    if (uploadQueueManager.inProgress) {
        [uploadQueueManager pauseQueue];
        [self.tableView setEditing:YES animated:YES];
    } else {
        [self.tableView setEditing:NO animated:YES];
        [uploadQueueManager startQueueIfNeeded];
    }
    [self setQueueButtonState];
}

- (void)refresh;
{
    [[ContactsStreamManager sharedContactsStreamManager] refresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[CacheManager sharedCacheManager] flushMemoryCache];
}

- (StreamPhoto *)streamPhotoAtIndexPath:(NSIndexPath*)indexPath {
    NSMutableArray *photos = [ContactsStreamManager sharedContactsStreamManager].photos;
    if ([photos count] == 0) {
        return nil;
    }
    NSMutableArray *photoUploads = uploadQueueManager.photoUploads;
    if (indexPath.section < [photoUploads count]) {
        // upload cell
        return nil;
    }
    NSInteger photoIndex = indexPath.section - [photoUploads count];
    return [photos objectAtIndex:photoIndex];
}

- (PhotoUpload*)photoUploadAtIndexPath:(NSIndexPath*)indexPath;
{
    NSMutableArray *photoUploads = uploadQueueManager.photoUploads;
    if ([photoUploads count] == 0) {
        return nil;
    }
    if (indexPath.section < [photoUploads count]) {
        return [uploadQueueManager.photoUploads objectAtIndex:indexPath.section];
    }
    return nil;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSMutableArray *photos = [ContactsStreamManager sharedContactsStreamManager].photos;
	NSInteger photosCount = photos.count == 0 ? 1 : photos.count;
    return photosCount + [uploadQueueManager.photoUploads count];
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PhotoUpload *upload = [self photoUploadAtIndexPath:indexPath];
    if (upload) {
        PhotoUploadCell *cell = [[PhotoUploadCell alloc] initWithPhotoUpload:upload];        
        return [cell autorelease];
    }
    
    StreamPhoto *photo = [self streamPhotoAtIndexPath:indexPath];
    if (photo) {
        // TODO - reuse identifier removed for now because of deferred loading bugs. Needs to come back at some point.
        StreamPhotoViewCell *cell = (StreamPhotoViewCell*)[tableView dequeueReusableCellWithIdentifier:nil];
        if (cell == nil) {
            CGRect bounds = self.view.bounds;
            cell = [[[StreamPhotoViewCell alloc] initWithBounds:bounds] autorelease];
        }
        [cell populateFromPhoto:photo];
        return cell;
    }

    
    // no photos to display. Placeholder.
    // TODO - if this is the first run, this might be because we haven't loaded any
    // photos yet.
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    cell.textLabel.text = @"No photos from your contacts";
    cell.textLabel.textColor = [UIColor grayColor];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return [cell autorelease];
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PhotoUpload *upload = [self photoUploadAtIndexPath:indexPath];
    if (upload) {
        return 60.0f;
    }

    StreamPhoto *photo = [self streamPhotoAtIndexPath:indexPath];
    if (photo) {
        return [StreamPhotoViewCell cellHeightForPhoto:photo width:IMAGE_WIDTH];
    }
    
    return 100.0f;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    StreamPhoto *photo = [self streamPhotoAtIndexPath:indexPath];
    if (photo) {
        [[UIApplication sharedApplication] openURL:photo.mobilePageURL];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;
{
    PhotoUpload *upload = [self photoUploadAtIndexPath:indexPath];
    if (upload) {
        return !uploadQueueManager.inProgress;
    } else {
        return NO;
    }
}

-(UILabel*) addLabelWithFrame:(CGRect)frame fontSize:(int)size bold:(BOOL)bold color:(UIColor*)color;
{
    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    label.textAlignment = UITextAlignmentLeft;
    if (bold) {
        label.font = [UIFont boldSystemFontOfSize:size];
    } else {
        label.font = [UIFont systemFontOfSize:size];
    }
    label.contentMode = UIViewContentModeTopLeft;
    label.textColor = color;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.minimumFontSize = size;
    label.numberOfLines = 0;
    
    [label autorelease];
    return label;
}



- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section 
{
    NSIndexPath *tempIndex = [NSIndexPath indexPathForRow:0 inSection:section];
    StreamPhoto *photo = [self streamPhotoAtIndexPath:tempIndex];
    if (!photo) {
        return nil;
    }
        
    UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, tableView.sectionHeaderHeight)] autorelease];

    CGRect avatarRect = CGRectMake(PADDING_SIZE, PADDING_SIZE, AVATAR_SIZE, AVATAR_SIZE);
    RemoteImageView *avatarView = [[[RemoteImageView alloc] initWithFrame:avatarRect] autorelease];
    [headerView addSubview:avatarView];
    [avatarView loadURL:photo.avatarURL];

    CGFloat line1_top = PADDING_SIZE;
    CGFloat line2_top = line1_top + AVATAR_SIZE / 2;
    CGFloat line_height = AVATAR_SIZE / 2;
    CGFloat line_left = PADDING_SIZE + AVATAR_SIZE + PADDING_SIZE;
    CGFloat line_width = IMAGE_WIDTH - (AVATAR_SIZE + PADDING_SIZE + TIMEBOX_SIZE);
    CGFloat timebox_left = tableView.bounds.size.width - (PADDING_SIZE + TIMEBOX_SIZE);

    // labels top-left
    UILabel *usernameView = [self addLabelWithFrame:CGRectMake(line_left, line1_top, line_width, line_height)
                                  fontSize:HEADER_FONT_SIZE
                                      bold:YES
                                     color:[UIColor colorWithRed:0.1 green:0.4 blue:0.7 alpha:1]];
    usernameView.backgroundColor = [UIColor clearColor];
    [headerView addSubview:usernameView];
    
    UILabel *placeView =    [self addLabelWithFrame:CGRectMake(line_left, line2_top, line_width, line_height)
                                  fontSize:HEADER_FONT_SIZE
                                      bold:YES
                                     color:[UIColor colorWithWhite:0.4 alpha:1]];
    placeView.backgroundColor = [UIColor clearColor];
    [headerView addSubview:placeView];
    
    if ([photo.placename length] > 0) {
        // layer a button over the top of the place so you can tap it.
        UIButton *placeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        placeButton.frame = placeView.frame;
        [placeButton addTarget:self action:@selector(tapPlace:event:) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:placeButton];
    }
    
    // labels top-right
    UILabel *visibilityView =  [self addLabelWithFrame:CGRectMake(timebox_left, line1_top, TIMEBOX_SIZE, line_height)
                                     fontSize:HEADER_FONT_SIZE
                                         bold:YES
                                        color:[UIColor colorWithWhite:0.6 alpha:1]];
    visibilityView.textAlignment = UITextAlignmentRight;
    visibilityView.backgroundColor = [UIColor clearColor];
    [headerView addSubview:visibilityView];
    
    UILabel *timeagoView =  [self addLabelWithFrame:CGRectMake(timebox_left, line2_top, TIMEBOX_SIZE, line_height)
                                  fontSize:HEADER_FONT_SIZE
                                      bold:YES
                                     color:[UIColor colorWithWhite:0.6 alpha:1]];
    timeagoView.textAlignment = UITextAlignmentRight;
    timeagoView.backgroundColor = [UIColor clearColor];
    [headerView addSubview:timeagoView];

    usernameView.text = photo.ownername;
    // gfx are for losers. I like unicode.
    timeagoView.text = [@"⌚" stringByAppendingString:photo.ago];
    placeView.text = photo.placename;
    int vis = photo.visibility;
    if (vis == StreamPhotoVisibilityPrivate) {
        visibilityView.text = @"private";
        visibilityView.textColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:1];
    } else if (vis == StreamPhotoVisibilityLimited) {
        visibilityView.text = @"limited";
        visibilityView.textColor = [UIColor colorWithRed:0.7 green:0.7 blue:0 alpha:1];
    } else if (vis == StreamPhotoVisibilityPublic) {
        visibilityView.text = @"public";
        visibilityView.textColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
    }

    headerView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    return headerView;
}

- (void)tapPlace:(UIView*)sender event:(UIEvent*)event;
{
    NSLog(@"sender %@ got event %@", sender, event);
    UITouch *first = [[event allTouches] anyObject];
    NSLog(@"first touch is %@", first);
    CGPoint loc = [first locationInView:self.tableView];
    NSLog(@"location in view is %f,%f", loc.x, loc.y);
    // zomg hack. the touch is in the header, which isn't in any row. but
    // 20 pixels lower will be in the image! (gahrghrhag)
    CGPoint locInRow = CGPointMake(loc.x, loc.y + 20);
    NSIndexPath *path = [self.tableView indexPathForRowAtPoint:locInRow];
    NSLog(@"touc is at path %@",path);

    StreamPhoto *photo = [self streamPhotoAtIndexPath:path];
    [[UIApplication sharedApplication] openURL:photo.mapPageURL];
    
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		[uploadQueueManager removePhotoUploadAtIndex:indexPath.section];
		//[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		// TOOD: use deleteRowsAtIndexPaths
		//[self.tableView reloadData];
    }   
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Remove";
}

# pragma mark memory management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [queueButton release];
    [uploadQueueManager release];
    [super dealloc];
}


@end

