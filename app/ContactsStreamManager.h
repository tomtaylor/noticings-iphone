//
//  ContactsStreamManager.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoStreamManager.h"

@interface ContactsStreamManager : PhotoStreamManager

+(ContactsStreamManager *)sharedContactsStreamManager;

@end


