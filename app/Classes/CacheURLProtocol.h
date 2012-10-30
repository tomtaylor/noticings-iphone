//
//  CacheURLProtocol.h
//  Noticings
//
//  Created by Tom Insam on 14/05/2012.
//  Copyright (c) 2012 Tom Insam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CacheURLProtocol : NSURLProtocol

@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLResponse *response;

// property to stop recursive requests.
// http://stackoverflow.com/questions/2494831/intercept-web-requests-from-a-webview-flash-plugin
#define NOCACHE_REQUEST_HEADER_TAG  @"noticings-cache"

@end
