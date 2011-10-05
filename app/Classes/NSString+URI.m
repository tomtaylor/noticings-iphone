//
//  NSString+URI.m
//  Noticings
//
//  Created by Tom Insam on 05/10/2011.
//  Copyright (c) 2011 Strange Tractor Limited. All rights reserved.
//

#import "NSString+URI.h"

@implementation NSString(URI)

- (NSString *)stringByEncodingForURI;
{
    NSString * encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                   NULL,
                                                                                   (CFStringRef)self,
                                                                                   NULL,
                                                                                   (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                   kCFStringEncodingUTF8 );
    return [encodedString autorelease];
}

- (NSString *)stringByDecodingFromURI;
{
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
