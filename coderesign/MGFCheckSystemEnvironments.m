//
//  checkSystemEnvironments.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFCheckSystemEnvironments.h"

@implementation MGFCheckSystemEnvironments

- (void)mgf_checkSystemEnvironments
{
    [DebugLog showDebugLog:@"############################################################################ Checking system environments..." withDebugLevel:Debug];
    
    BOOL isSuccess = TRUE;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/zip"]) {
        [DebugLog showDebugLog:@"This app cannot run without the zip utility present at /usr/bin/zip" withDebugLevel:Error];
        isSuccess = FALSE;
    }else{
        [DebugLog showDebugLog:@"Checking zip: Installed" withDebugLevel:Debug];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/unzip"]) {
        [DebugLog showDebugLog:@"This app cannot run without the zip utility present at /usr/bin/unzip" withDebugLevel:Error];
        isSuccess = FALSE;
    }else{
        [DebugLog showDebugLog:@"Checking unzip: Installed" withDebugLevel:Debug];
    }
    
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/codesign"]) {
        [DebugLog showDebugLog:@"This app cannot run without the zip utility present at /usr/bin/codesign" withDebugLevel:Error];
        isSuccess = FALSE;
    }else{
        [DebugLog showDebugLog:@"Checking codesign: Installed" withDebugLevel:Debug];
    }
    
    
    [self mgf_invokeDelegate:self withFinished:isSuccess withObject:nil];
}
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}
@end
