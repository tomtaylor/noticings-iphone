//
//  RemoteImageView.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CacheManager.h"

@interface RemoteImageView : UIImageView <DeferredImageLoader> {
}

-(id)initWithFrame:(CGRect)frame;
- (void)loadURL:(NSURL*)url;
- (void)setImage:(UIImage*)theImage withAnimation:(BOOL)animate;

@property (retain) NSURL* url;

@end
