//
//  CacheManager.m
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import "CacheManager.h"

#import <CommonCrypto/CommonDigest.h>

#import "StreamPhoto.h"

@implementation CacheManager

extern const NSUInteger kMaxDiskCacheSize;

- (id)init;
{
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        self.cacheDir = [paths[0] stringByAppendingPathComponent:@"imageCache"];
        
        // create cache directory if it doesn't exist already.
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.cacheDir]) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:self.cacheDir
                                           withIntermediateDirectories:YES
                                                            attributes:nil
                                                                 error:nil]) {
                NSLog(@"can't create cache folder");
            }
        }
        
    }
    
    return self;
}


-(NSString*) sha256:(NSString *)clear{
    const char *s=[clear cStringUsingEncoding:NSASCIIStringEncoding];
    NSData *keyData=[NSData dataWithBytes:s length:strlen(s)];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH]={0};
    CC_SHA256(keyData.bytes, keyData.length, digest);
    NSData *out=[NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    NSString *hash=[out description];
    hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@">" withString:@""];
    return hash;
}

-(NSString*) cachePathForFilename:(NSString*)filename;
{
    return [self.cacheDir stringByAppendingPathComponent:filename];
}

-(NSString*) urlToFilename:(NSURL*)url;
{
    NSString *hash = [self sha256:[url absoluteString]];
    return [self cachePathForFilename:[hash stringByAppendingPathExtension:@"jpg"]];
}

- (void) clearCache;
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    for (NSString *file in [fm contentsOfDirectoryAtPath:self.cacheDir error:&error]) {
        NSString *fullFile = [self.cacheDir stringByAppendingPathComponent:file];
        NSLog(@"deleting %@ from cache", fullFile);
        BOOL success = [fm removeItemAtPath:fullFile error:&error];
        if (!success || error) {
            NSLog(@"Fail! %@", error);
        }
    }
}

-(void)reapCache;
{
    NSFileManager *manager = [NSFileManager defaultManager];
    for (NSString *subPath in [manager subpathsAtPath:self.cacheDir]) {
        DLog(@"Found %@", subPath);
        NSString *fullPath = [self.cacheDir stringByAppendingPathComponent:subPath];
        NSDictionary* fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
        NSDate *result = [fileAttribs fileCreationDate]; //or fileModificationDate
        if ([[NSDate date] timeIntervalSinceDate:result] > 3600 * 24 * 7) {
            DLog(@"File is more than a week old. Reaping.");
            [manager removeItemAtPath:fullPath error:nil];
        }
    }

}

@end
