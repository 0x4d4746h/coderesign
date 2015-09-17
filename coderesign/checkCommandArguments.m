//
//  checkCommandArguments.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "checkCommandArguments.h"
#import "DebugLog.h"
#import "SharedData.h"

@implementation checkCommandArguments

+ (BOOL)checkArguments:(const char *[])argv number:(int)argc
{
    [DebugLog showDebugLog:@"############################################################################ Checking passed arguments..." withDebugLevel:Info];
    
    if (argc < ([SharedData sharedInstance].standardCommands.count +1)) {
        // show the command's useage
        [DebugLog showDebugLog:@"More or less arguments for codreesign, please confirm and retry!" withDebugLevel:Error];
        exit(0);
    }
    
    NSMutableArray *passed_command_flags_ = [NSMutableArray new];
    NSMutableArray *passed_values_ = [NSMutableArray new];
    
    for (int i=0; i<argc; i++) {
        
        NSString *ns_argv = [NSString stringWithUTF8String:argv[i]];
        
        if ((i % 2) > 0) {
            [passed_command_flags_ addObject:ns_argv];
            if (![[SharedData sharedInstance].standardCommands containsObject:ns_argv]) {
                NSString *errorInfo = [NSString stringWithFormat:@"Option '%@' is not support, please confirm and retry!", ns_argv];
                [DebugLog showDebugLog:errorInfo withDebugLevel:Error];
                exit(0);
            }
        }else {
            [passed_values_ addObject:ns_argv];
        }
    }
    
    //remove the coderesign path arguments
    [passed_values_ removeObjectAtIndex:0];
    
    [SharedData sharedInstance].crossedArguments  = [NSDictionary dictionaryWithObjects:passed_values_ forKeys:passed_command_flags_];
    [DebugLog showDebugLog:[SharedData sharedInstance].crossedArguments withDebugLevel:Info];
    
    NSString *ipa               = [SharedData sharedInstance].crossedArguments[minus_d];
    NSString *mobileProvision   = [SharedData sharedInstance].crossedArguments[minus_p];
    NSString *entitlements      = [SharedData sharedInstance].crossedArguments[minus_e];
    NSString *bundleID          = [SharedData sharedInstance].crossedArguments[minus_id];
    NSString *distributionCerName   = [SharedData sharedInstance].crossedArguments[minus_cer];
    NSString *py = [SharedData sharedInstance].crossedArguments[minus_py];
    
    if (!([[[ipa pathExtension]lowercaseString] isEqualToString:@"ipa"])) {
        [DebugLog showDebugLog:@"ipa file type is not right, please confirm and retry!" withDebugLevel:Error];
        exit(0);
    }
    
    if (!([[[mobileProvision pathExtension]lowercaseString] isEqualToString:@"mobileprovision"])) {
        [DebugLog showDebugLog:@"mobileprovision file type is not right, please confirm and retry!" withDebugLevel:Error];
        exit(0);
    }
    
    if (!([[[entitlements pathExtension]lowercaseString] isEqualToString:@"plist"])) {
        [DebugLog showDebugLog:@"entitlements file type is not right, please confirm and retry!" withDebugLevel:Error];
        exit(0);
    }
    
    if (!bundleID && [bundleID length] == 0) {
        [DebugLog showDebugLog:@"bundle identifler can't be empty, please confirm and retry!" withDebugLevel:Error];
        exit(0);
    }
    
    if (!distributionCerName && [distributionCerName length] == 0) {
        [DebugLog showDebugLog:@"distributionCer name or App ID prefiex can't be empty, please confirm and retry!" withDebugLevel:Error];
        exit(0);
    }
    if (!py && [py length] == 0) {
        [DebugLog showDebugLog:@"python scripy is empty please confirm and retry!" withDebugLevel:Error];
        exit(0);
    }
    
    [DebugLog showDebugLog:Pass];
    return true;
}
@end
