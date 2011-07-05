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

@implementation StreamViewController

@synthesize photos;

- (void)viewDidLoad {
    [super viewDidLoad];

   
    refreshButton = [[UIBarButtonItem alloc] 
                     initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                          target:self
                                          action:@selector(refreshButtonPressed)];
	
	[[self navigationItem] setRightBarButtonItem:refreshButton];
    [refreshButton release];
    
    self.photos = [NSMutableArray arrayWithCapacity:50];
    
    [self performSelector:@selector(refreshButtonPressed) withObject:nil afterDelay:0.1];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)refreshButtonPressed;
{
    NSLog(@"refresh!");
    
    NSString *extras = @"date_upload,date_taken,owner_name,icon_server,geo,path_alias";
    
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:@"6", @"count", extras, @"extras", @"1", @"include_self", nil];
    
    [[self flickrRequest] callAPIMethodWithGET:@"flickr.photos.getContactsPhotos" arguments:args];
}

// TODO - stolen from the uploader. refactor into base class?
- (OFFlickrAPIRequest *)flickrRequest;
{
	if (!flickrRequest) {
		OFFlickrAPIContext *apiContext = [[OFFlickrAPIContext alloc] initWithAPIKey:FLICKR_API_KEY sharedSecret:FLICKR_API_SECRET];
		[apiContext setAuthToken:[[NSUserDefaults standardUserDefaults] stringForKey:@"authToken"]];
		flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:apiContext];
		flickrRequest.delegate = self;
		flickrRequest.requestTimeoutInterval = 45;
		[apiContext release];
	}
	
	return flickrRequest;
}


#pragma mark Flickr delegate methods


- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
    [self.photos removeAllObjects];
    NSLog(@"completed flickr request!");
    NSLog(@"got %@", inResponseDictionary);
    for (NSDictionary *photo in [inResponseDictionary valueForKeyPath:@"photos.photo"]) {
        StreamPhoto *sp = [[StreamPhoto alloc] initWithDictionary:photo];
        NSLog(@"got photo %@", sp.title);
        [self.photos addObject:sp];
        [sp release];
    }
    [self.tableView reloadData];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
    NSLog(@"failed flickr request!");
}



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.photos.count == 0) {
        return 1;
    }
    return self.photos.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if (self.photos.count == 0) {
		UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:nil] autorelease];
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.textLabel.text = @"No photos from your contacts";
		cell.textLabel.textColor = [UIColor grayColor];
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;

	} else {
        StreamPhotoViewCell *cell = (StreamPhotoViewCell*)[tableView dequeueReusableCellWithIdentifier:@"streamCell"];
        if (cell == nil) {
            CGRect bounds = self.view.bounds;
            cell = [[[StreamPhotoViewCell alloc] initWithBounds:bounds] autorelease];
        } 
        
        StreamPhoto *photo = [self.photos objectAtIndex:indexPath.row];
        [cell populateFromPhoto:photo];
        
        return cell;
	}
	
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 400.0f;
}

- (void)dealloc {
    [super dealloc];
}


@end

