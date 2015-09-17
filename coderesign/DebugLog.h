//
//  DebugLog.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum {
    Info = 0,
    Debug,
    Error
}DebugLevel;

typedef enum {
    Pass = 0,
    Failed,
    AllPass,
    AllDone,
    Warning
}DebugResult;

@interface DebugLog : NSObject

+ (void)showDebugLog:(id)debugMessage withDebugLevel:(DebugLevel)level;
+ (void)showDebugLog:(DebugResult)result;

@end
