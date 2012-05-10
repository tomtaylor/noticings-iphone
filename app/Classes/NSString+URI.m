//
//  NSString+URI.m
//  Noticings
//
//  Created by Tom Insam on 05/10/2011.
//  Copyright (c) 2011 Tom Insam.
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

- (NSString *)stringByEncodingForJavaScript;
{
    // wrong, but enough for our purposes.
    NSString *temp = [self stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    temp = [temp stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    temp = [temp stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    return temp;
}

@end
