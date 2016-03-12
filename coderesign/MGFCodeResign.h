//
//  coderesign.h
//  coderesign
//
//  Created by MiaoGuangfa on 7/24/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MGFCodeResign : NSObject

+ (id)sharedInstance;
- (void)runCodeResignWithArgv:(const char *[])argv argumentsNumber:(int)argc;

@end
