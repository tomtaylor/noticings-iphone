//
//  MetadataFetcher.h
//  Noticings
//
//  Created by Tom Insam on 2012/10/30.
//
//

#import <Foundation/Foundation.h>

@interface MetadataFetcher : NSObject

@property (nonatomic, strong) NSOperationQueue* queue;

- (void)fetchPhotos;


@end
