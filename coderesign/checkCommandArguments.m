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
//    if (argc == 3) {
//        
//        [SharedData sharedInstance].isOnlyDecodeIcon = YES;
//    }else if (argc < ([SharedData sharedInstance].standardCommands.count +1)) {
//        // show the command's useage
//
//        [DebugLog showDebugLog:@"More or less arguments for codreesign, please confirm and retry!" withDebugLevel:Error];
//        
//        exit(0);
//    }
    
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
//    NSLog(@"passed_command_flags_ > %@", passed_command_flags_);
//    NSLog(@"passed_values_ > %@", passed_values_);
    if (passed_command_flags_.count != passed_values_.count) {
        [DebugLog showDebugLog:@"Missed arguments for options" withDebugLevel:Error];
        exit(0);
    }
    [SharedData sharedInstance].crossedArguments  = [NSDictionary dictionaryWithObjects:passed_values_ forKeys:passed_command_flags_];
    
    [DebugLog showDebugLog:[SharedData sharedInstance].crossedArguments withDebugLevel:Info];
    
    if([passed_command_flags_ containsObject:@"-d"]) {
        
        NSString *ipa               = [SharedData sharedInstance].crossedArguments[minus_d];
        if (ipa == NULL || !([[[ipa pathExtension]lowercaseString] isEqualToString:@"ipa"])) {
            [DebugLog showDebugLog:@"ipa path is not input or file type is not right, please confirm and retry!" withDebugLevel:Error];
            exit(0);
        }
        
        
        if ([passed_command_flags_ containsObject:@"-p"] && [passed_command_flags_ containsObject:@"-ci"] ) {
            NSString *mobileProvision   = [SharedData sharedInstance].crossedArguments[minus_p];
            NSString *distributionCerName   = [SharedData sharedInstance].crossedArguments[minus_cer];
            
            
            if ( mobileProvision==NULL || !([[[mobileProvision pathExtension]lowercaseString] isEqualToString:@"mobileprovision"])) {
                
                [DebugLog showDebugLog:@"mobileprovision is not put or file type is not right, please confirm and retry!" withDebugLevel:Error];
                if ((distributionCerName == NULL || [distributionCerName length] == 0)) {
                    [DebugLog showDebugLog:@"distributionCer name or App ID prefiex can't be empty, please confirm and retry!" withDebugLevel:Error];
                }
                exit(0);
            }
            
            if ([passed_command_flags_ containsObject:@"-py"]) {
                NSString *py = [SharedData sharedInstance].crossedArguments[minus_py];
                if (py==NULL || [py length] == 0) {
                    [DebugLog showDebugLog:@"python scripy is empty please confirm and retry!" withDebugLevel:Error];
                    exit(0);
                }
                
                [SharedData sharedInstance].isResignAndDecode = YES;
                [DebugLog showDebugLog:@"You will do resign and decode icon action" withDebugLevel:Info];
            }else {
                [SharedData sharedInstance].isOnlyResign = YES;
                [DebugLog showDebugLog:@"You will only do resign action" withDebugLevel:Info];
            }
        }else{
            if ([passed_command_flags_ containsObject:@"-py"]) {
                NSString *py = [SharedData sharedInstance].crossedArguments[minus_py];
                if (py==NULL || [py length] == 0) {
                    [DebugLog showDebugLog:@"python scripy is empty please confirm and retry!" withDebugLevel:Error];
                    exit(0);
                }
                
                [SharedData sharedInstance].isOnlyDecodeIcon = YES;
                [DebugLog showDebugLog:@"You will only do decode icon action" withDebugLevel:Info];
            }else{
                [DebugLog showDebugLog:@"-p, - ci options are missing or -py is missing" withDebugLevel:Error];
                exit(0);
            }
        }
    }else{
        [DebugLog showDebugLog:@"-d is missing" withDebugLevel:Error];
        exit(0);
    }
    
    [DebugLog showDebugLog:Pass];
    
    NSString *sourcePath = [SharedData sharedInstance].crossedArguments[minus_d];
    NSArray *destinationPathComponents = [sourcePath pathComponents];
    NSString *destinationPath = @"";
    
    for (int i = 0; i < ([destinationPathComponents count]-1); i++) {
        destinationPath = [destinationPath stringByAppendingPathComponent:[destinationPathComponents objectAtIndex:i]];
    }
    NSString *_tempPath = [destinationPath stringByAppendingPathComponent:@"temp"];
    [[NSFileManager defaultManager]createDirectoryAtPath:_tempPath withIntermediateDirectories:YES attributes:nil error:nil];
    [SharedData sharedInstance].commandPath = destinationPath;
    [SharedData sharedInstance].tempPath = _tempPath;
    return true;
}
@end
