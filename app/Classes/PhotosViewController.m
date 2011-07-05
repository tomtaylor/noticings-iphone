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
#import "PhotoPreviewViewController.h"
#import "PhotoSaveViewController.h"
#import <ImageIO/ImageIO.h>

@interface PhotosViewController (Private)

- (NSDictionary *)gpsDictionaryForCurrentLocation;

@end

@implementation PhotosViewController

@synthesize currentLocation;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(assetsLibraryChanged:) 
                                                 name:ALAssetsLibraryChangedNotification 
                                               object:nil];
    
    BOOL isCameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    
    if (isCameraAvailable) {
        cameraButton = [[UIBarButtonItem alloc] 
                        initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                        target:self
                        action:@selector(cameraButtonPressed:)];
        
        [[self navigationItem] setRightBarButtonItem:cameraButton];
    }
	
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

- (void)cameraButtonPressed:(id)sender {
    [locationManager startUpdatingLocation];
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = NO;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    [self.navigationController presentModalViewController:imagePicker animated:YES];
    [imagePicker release];
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
    Photo *selectedPhoto = [photos objectAtIndex:indexPath.row];
    [self displayPreviewForPhoto:selectedPhoto];
}

#pragma mark -
#pragma mark UIImagePickerViewControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.navigationController dismissModalViewControllerAnimated:NO];
    PhotoSaveViewController *saveViewController = [[PhotoSaveViewController alloc] init];
    [self.navigationController presentModalViewController:saveViewController animated:NO];
    [saveViewController release];
    
    [locationManager stopUpdatingLocation];
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSDictionary *metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
    
    NSDictionary *gpsMetadata = [self gpsDictionaryForCurrentLocation];
    [metadata setValue:gpsMetadata forKey:(NSString *)kCGImagePropertyGPSDictionary];
    
    CGImageRef cgImage = [originalImage CGImage];
    
    [assetsLibrary 
     writeImageToSavedPhotosAlbum:cgImage
     metadata:metadata 
     completionBlock:^(NSURL *assetURL, NSError *error) {
         if (error) {
             NSLog(@"Error: %@", error);
         } else {
            [assetsLibrary assetForURL:assetURL 
                           resultBlock:^(ALAsset *asset) {
                               NSLog(@"Found asset");
                               Photo *photo = [[Photo alloc] initWithAsset:asset];
                               PhotoUpload *photoUpload = [[PhotoUpload alloc] initWithPhoto:photo];
                               [photo release];
                               
                               PhotoDetailViewController *photoDetailViewController = [[PhotoDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
                               
                               photoDetailViewController.photoUpload = photoUpload;
                               
                               
                               [self.navigationController dismissModalViewControllerAnimated:YES];
                               [self.navigationController pushViewController:photoDetailViewController animated:NO];
                               
                               
                               [photoUpload release];
                               [photoDetailViewController release];
                           }
                          failureBlock:^(NSError *error) {
                              NSLog(@"Error: %@", error);
                          }
             ];
         }
     }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [locationManager stopUpdatingLocation];
    [picker dismissModalViewControllerAnimated:YES];
}

- (NSDictionary *)gpsDictionaryForCurrentLocation {
    NSMutableDictionary *gps = [NSMutableDictionary dictionary];
    
    // GPS tag version
    [gps setObject:@"2.2.0.0" forKey:(NSString *)kCGImagePropertyGPSVersion];
    
    // Time and date must be provided as strings, not as an NSDate object
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss.SSSSSS"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [gps setObject:[formatter stringFromDate:self.currentLocation.timestamp] forKey:(NSString *)kCGImagePropertyGPSTimeStamp];
    [formatter setDateFormat:@"yyyy:MM:dd"];
    [gps setObject:[formatter stringFromDate:self.currentLocation.timestamp] forKey:(NSString *)kCGImagePropertyGPSDateStamp];
    [formatter release];
    
    // Latitude
    CGFloat latitude = self.currentLocation.coordinate.latitude;
    if (latitude < 0) {
        latitude = -latitude;
        [gps setObject:@"S" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    } else {
        [gps setObject:@"N" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    }
    [gps setObject:[NSNumber numberWithFloat:latitude] forKey:(NSString *)kCGImagePropertyGPSLatitude];
    
    // Longitude
    CGFloat longitude = self.currentLocation.coordinate.longitude;
    if (longitude < 0) {
        longitude = -longitude;
        [gps setObject:@"W" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    } else {
        [gps setObject:@"E" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    }
    [gps setObject:[NSNumber numberWithFloat:longitude] forKey:(NSString *)kCGImagePropertyGPSLongitude];
    
    // Altitude
    CGFloat altitude = self.currentLocation.altitude;
    if (!isnan(altitude)) {
        if (altitude < 0) {
            altitude = -altitude;
            [gps setObject:@"1" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        } else {
            [gps setObject:@"0" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        }
        [gps setObject:[NSNumber numberWithFloat:altitude] forKey:(NSString *)kCGImagePropertyGPSAltitude];
    }
    
    // Speed, must be converted from m/s to km/h
    if (self.currentLocation.speed >= 0) {
        [gps setObject:@"K" forKey:(NSString *)kCGImagePropertyGPSSpeedRef];
        [gps setObject:[NSNumber numberWithFloat:self.currentLocation.speed*3.6] forKey:(NSString *)kCGImagePropertyGPSSpeed];
    }
    
    // Heading
    if (self.currentLocation.course >= 0) {
        [gps setObject:@"T" forKey:(NSString *)kCGImagePropertyGPSTrackRef];
        [gps setObject:[NSNumber numberWithFloat:self.currentLocation.course] forKey:(NSString *)kCGImagePropertyGPSTrack];
    }
    
    return gps;
}
         
- (void)displayPreviewForPhoto:(Photo *)photo {
    PhotoPreviewViewController *previewViewController = [[PhotoPreviewViewController alloc] init];
    previewViewController.photo = photo;
    previewViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:previewViewController animated:YES];
    [previewViewController release];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager 
    didUpdateToLocation:(CLLocation *)newLocation 
           fromLocation:(CLLocation *)oldLocation
{
    if (abs([newLocation.timestamp timeIntervalSinceDate: [NSDate date]]) < 300) {
		self.currentLocation = newLocation;
		NSLog(@"Location updated to: %@", newLocation);
	}
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
    [locationManager release];
    [currentLocation release];
    [super dealloc];
}


@end

