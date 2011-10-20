//
//  DebugViewController.m
//  Noticings
//
//  Created by Tom Insam on 20/10/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "DebugViewController.h"
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
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
    UploadQueueManager *manager;
    
    switch (indexPath.section) {
        case kNoticingsDebugClearCache:
            [[CacheManager sharedCacheManager] clearCache];
            break;

        case kNoticingsDebugFakeUpload:
            manager = [UploadQueueManager sharedUploadQueueManager];
            [manager fakeUpload];
            break;
        default:
            break;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
