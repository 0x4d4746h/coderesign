//
//  coderesign.h
//  coderesign
//
//  Created by MiaoGuangfa on 7/24/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface coderesign : NSObject

+ (id) sharedInstance;
- (void) resignWithArgv:(const char *[])argv argumentsNumber:(int)argc;
- (void) prepare;

@end
