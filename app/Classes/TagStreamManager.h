//
//  TagStreamManager.h
//  Noticings
//
//  Created by Tom Insam on 05/10/2011.
//  Copyright (c) 2011 Tom Insam.
//

#import <Foundation/Foundation.h>
#import "PhotoStreamManager.h"

@interface TagStreamManager : PhotoStreamManager

-(id)initWithTag:(NSString*)tag;

@property (strong) NSString* tag;

@end
