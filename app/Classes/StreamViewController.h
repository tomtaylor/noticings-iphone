//
//  StreamViewController.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ObjectiveFlickr.h"
#import "FlickrAPIKeys.h"

@interface StreamViewController : UITableViewController<OFFlickrAPIRequestDelegate> {
    UIBarButtonItem *refreshButton;
	OFFlickrAPIRequest *flickrRequest;
    
    NSMutableArray *photos;

}

- (OFFlickrAPIRequest *)flickrRequest;

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError;

@property (retain) NSMutableArray *photos;

@end
