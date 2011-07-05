//
//  RemoteImageView.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RemoteImageView : UIImageView {
@private
    NSURLConnection* connection;
    NSMutableData* data;
}

-(id)initWithFrame:(CGRect)frame;
- (void)loadURL:(NSURL*)url;

@end
