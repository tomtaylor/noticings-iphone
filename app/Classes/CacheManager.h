//
//  CacheManager.h
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import <Foundation/Foundation.h>

@interface CacheManager : NSObject

- (NSString*) cachePathForFilename:(NSString*)filename;
- (NSString*) urlToFilename:(NSURL*)url;
- (void) clearCache;
- (void) reapCache;

@property (strong) NSString *cacheDir;

@end
