//
//  UserStreamManager.h
//  Noticings
//
//  Created by Tom Insam on 22/09/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import "PhotoStreamManager.h"

@interface UserStreamManager : PhotoStreamManager

-(id)initWithUser:(NSString*)userId;

@property (retain) NSString* userId;

@end
