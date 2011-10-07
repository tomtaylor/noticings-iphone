//
//  NSString+URI.h
//  Noticings
//
//  Created by Tom Insam on 05/10/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (URI)

- (NSString *)stringByEncodingForURI;
- (NSString *)stringByDecodingFromURI;
- (NSString *)stringByEncodingForJavaScript;

@end
