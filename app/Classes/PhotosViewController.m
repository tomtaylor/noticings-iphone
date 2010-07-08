//
//  PhotosViewController.m
//  Noticings
//
//  Created by Tom Taylor on 09/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PhotosViewController.h"
#import "Photo.h"
#import "PhotoUpload.h"
#import "PhotoDetailViewController.h"

@implementation PhotosViewController


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryChanged:) name:ALAssetsLibraryChangedNotification object:nil];
	
	[self loadPhotos];

}

- (void)loadPhotos {
	photosLoaded = NO;
	errorLoadingPhotos = NO;
	
	if (!timestampFormatter) {
		timestampFormatter = [[NSDateFormatter alloc] init];
		[timestampFormatter setDateFormat:@"EEEE MMMM d, HH:mm"];
	}
	
	if (!assetsLibrary) {
        assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
	
	if (!photos) {
		photos = [[NSMutableArray alloc] init];
	} else {
		[photos removeAllObjects];
	}
	
	[assetsLibrary 
	 enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
	 usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
		 [group setAssetsFilter:[ALAssetsFilter allPhotos]];
		 
		 NSCalendar *gregorian = [[NSCalendar alloc]
								  initWithCalendarIdentifier:NSGregorianCalendar];
		 NSDate *currentDate = [NSDate date];
		 NSDateComponents *comps = [[NSDateComponents alloc] init];
		 [comps setWeek:-2];
		 __block NSDate *twoWeeksAgoDate = [gregorian dateByAddingComponents:comps toDate:currentDate  options:0];
		 [comps release];
		 [gregorian release];
		 
		 [group enumerateAssetsWithOptions:(NSEnumerationReverse) 
								usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
									
									if (result) {
										NSDate *timestamp = [result valueForProperty:ALAssetPropertyDate];
										if (timestamp && [[timestamp earlierDate:twoWeeksAgoDate] isEqual:twoWeeksAgoDate]) {
											Photo *photo = [[Photo alloc] initWithAsset:result];
											[photos addObject:photo];
											[photo release];
										}
									}
									
									if (stop) {
										photosLoaded = YES;
										[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
									}
									
								}];
	 }
	 
	 failureBlock:^(NSError *error) {
		 NSLog(@"Failure loading assets: %@", error);
		 photosLoaded = YES;
		 errorLoadingPhotos = YES;
		 [self.tableView reloadData];
	 }
	 ];
}

- (void)assetsLibraryChanged:(NSNotification *)notification {
    [self loadPhotos];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (!photosLoaded || [photos count] < 1) {
		return 1;
	} else {
		return [photos count];
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (!photosLoaded || [photos count] < 1) {
		UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		
		if (!photosLoaded) {
			cell.textLabel.text = @"Loading photos...";
		} else if (errorLoadingPhotos) {
			cell.textLabel.text = @"There was problem loading your photos";
		} else {
			cell.textLabel.text = @"There aren't any photos taken within 2 weeks";
		}
		
		cell.textLabel.textColor = [UIColor grayColor];
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	} else {
		static NSString *CellIdentifier = @"PhotoCell";
		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		}
		
		Photo *photo = [photos objectAtIndex:indexPath.row];
		
		UIImage *thumbnailImage = photo.thumbnailImage;
		NSString *timestamp = [timestampFormatter stringFromDate:photo.timestamp];
		CLLocation *location = photo.location;
		
		if (timestamp == nil) {
			cell.textLabel.text = @"Unknown time";
		} else {
			cell.textLabel.text = timestamp;
		}
		
		if (location) {
			NSString *latitudeString = [self formatDegrees:location.coordinate.latitude];
			NSString *longitudeString = [self formatDegrees:location.coordinate.longitude];
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", latitudeString, longitudeString];
		} else {
			cell.detailTextLabel.text = @"Unknown location";
		}
		
		cell.imageView.image = thumbnailImage;

		return cell;
	}
}

- (NSString *)formatDegrees:(CLLocationDegrees)locationDegrees {
	int degrees = locationDegrees;
	double decimal = fabs(locationDegrees - degrees);
	int minutes = decimal * 60;
	double seconds = decimal * 3600 - minutes * 60;
	return [NSString stringWithFormat:@"%d° %d' %1.2f\"", 
								 degrees, minutes, seconds];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 75.0f;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	PhotoDetailViewController *photoDetailViewController = [[PhotoDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
	Photo *selectedPhoto = [photos objectAtIndex:indexPath.row];
	PhotoUpload *photoUpload = [[PhotoUpload alloc] initWithPhoto:selectedPhoto];
	photoDetailViewController.photoUpload = photoUpload;
	[self.navigationController pushViewController:photoDetailViewController animated:YES];
	[photoUpload release];
	[photoDetailViewController release];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	[photos makeObjectsPerformSelector:@selector(freeCache)];
}

- (void)dealloc {
	[timestampFormatter release];
	[assetsLibrary release];
	[photos release];	
    [super dealloc];
}


@end

