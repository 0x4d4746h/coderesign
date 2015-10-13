//
//  DebugLog.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "DebugLog.h"

@implementation DebugLog

+ (void)showDebugLog:(id)debugMessage withDebugLevel:(DebugLevel)level
{
    if (Error == level) {
        NSLog(@"[Error]: %@", debugMessage);
        NSLog(@"[Error]:############################################################################ [Failed]");
    }else if (Debug == level) {
#ifdef SHOW_DEBUG_LOG
        NSLog(@"[Debug]: %@", debugMessage);
#endif
    }else if (Info == level) {
        NSLog(@"[Info]: %@", debugMessage);
    }
}

+ (void)showDebugLog:(DebugResult)result {
    if (result == Pass) {
        NSLog(@"[Info]:############################################################################ [Pass]");
    }else if(result == Failed){
        NSLog(@"[Error]:############################################################################ [Failed]");
    }else if (result == AllPass) {
        NSLog(@"[Info]:############################################################################ [All Pass]");
    }else if (result == AllDone) {
        NSLog(@"[Info]:############################################################################ [All Done]");
    }else if (result == Warning) {
        NSLog(@"[Info]:############################################################################ [Warning]");
    }
}

@end
