//
//  checkSystemEnvironments.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "checkSystemEnvironments.h"
#import "DebugLog.h"
#import "SharedData.h"

@implementation checkSystemEnvironments

+ (BOOL)doCheckSystemEnvironments
{
    [DebugLog showDebugLog:@"############################################################################ Checking system environments..." withDebugLevel:Info];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/zip"]) {
        [DebugLog showDebugLog:@"This app cannot run without the zip utility present at /usr/bin/zip" withDebugLevel:Error];
        exit(0);
    }else{
        [DebugLog showDebugLog:@"Checking zip: Installed" withDebugLevel:Info];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/unzip"]) {
        [DebugLog showDebugLog:@"This app cannot run without the zip utility present at /usr/bin/unzip" withDebugLevel:Error];
        exit(0);
    }else{
        [DebugLog showDebugLog:@"Checking unzip: Installed" withDebugLevel:Info];
    }
    
    if (![SharedData sharedInstance].isOnlyDecodeIcon) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/codesign"]) {
            [DebugLog showDebugLog:@"This app cannot run without the zip utility present at /usr/bin/codesign" withDebugLevel:Error];
            exit(0);
        }else{
            [DebugLog showDebugLog:@"Checking codesign: Installed" withDebugLevel:Info];
        }
    }
    
    [DebugLog showDebugLog:AllPass];
    return true;
}
@end
