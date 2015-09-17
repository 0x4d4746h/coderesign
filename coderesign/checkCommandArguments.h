//
//  checkCommandArguments.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface checkCommandArguments : NSObject

+ (BOOL) checkArguments:(const char *[])argv number:(int)argc;

@end
