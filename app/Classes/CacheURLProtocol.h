//
//  CacheURLProtocol.h
//  Noticings
//
//  Created by Tom Insam on 14/05/2012.
//  Copyright (c) 2012 Lanyrd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CacheURLProtocol : NSURLProtocol

@property (nonatomic, retain) NSURLRequest *request;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) NSURLResponse *response;

@end
