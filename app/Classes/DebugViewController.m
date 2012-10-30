//
//  DebugViewController.m
//  Noticings
//
//  Created by Tom Insam on 20/10/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import "DebugViewController.h"
#import "NoticingsAppDelegate.h"
#import "CacheManager.h"
#import "UploadQueueManager.h"

enum DebugActions {
	kNoticingsDebugClearCache = 0,
	kNoticingsDebugFakeUpload,
	NUM_DEBUG_ACTIONS
};

@implementation DebugViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_DEBUG_ACTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
    switch (indexPath.section) {
        case kNoticingsDebugClearCache:
            cell.textLabel.text = @"Clear cache";
            break;
        case kNoticingsDebugFakeUpload:
            cell.textLabel.text = @"Fake upload";
            break;
        default:
            break;
    }	

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    switch (indexPath.section) {
        case kNoticingsDebugClearCache:
            [[NoticingsAppDelegate delegate].cacheManager clearCache];
            break;

        case kNoticingsDebugFakeUpload:
            [[NoticingsAppDelegate delegate].uploadQueueManager fakeUpload];
            break;

        default:
            break;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
