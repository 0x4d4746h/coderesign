//
//  parsePlayload.h
//  coderesign
//
//  Created by MiaoGuangfa on 10/10/15.
//  Copyright © 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface parsePlayload : NSObject

+ (parsePlayload *) sharedInstance;

- (void) parse;

@end
