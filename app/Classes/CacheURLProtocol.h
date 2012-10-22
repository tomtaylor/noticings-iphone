//
//  CacheURLProtocol.h
//  Noticings
//
//  Created by Tom Insam on 14/05/2012.
//  Copyright (c) 2012 Lanyrd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CacheURLProtocol : NSURLProtocol

@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLResponse *response;

@end
