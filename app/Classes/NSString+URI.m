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
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (__bridge CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 kCFStringEncodingUTF8);
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

-(NSDictionary*)dictionaryByParsingAsQueryParameters;
{
    NSMutableDictionary *parsed = [NSMutableDictionary dictionary];
    [[self componentsSeparatedByString:@"&"] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        NSArray *bits = [obj componentsSeparatedByString:@"="];
        if (bits.count == 2) {
            NSString *k = [bits[0] stringByDecodingFromURI];
            NSString *v = [bits[1] stringByDecodingFromURI];
            [parsed setValue:v forKey:k];
        }
    }];
    return [NSDictionary dictionaryWithDictionary:parsed];
}

@end
