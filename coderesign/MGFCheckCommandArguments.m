//
//  checkCommandArguments.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFCheckCommandArguments.h"

@implementation MGFCheckCommandArguments


- (void)mgf_checkArguments:(const char *[])argv number:(int)argc
{
    [DebugLog showDebugLog:@"############################################################################ Checking passed arguments..." withDebugLevel:Debug];
    
    /**
     * Compare the passed arguments with standard commands
     * if not, exit.
     */
    NSMutableArray *passed_command_flags_ = [NSMutableArray new];
    NSMutableArray *passed_values_ = [NSMutableArray new];
    for (int i=0; i<argc; i++) {
        NSString *ns_argv = [NSString stringWithUTF8String:argv[i]];
        
        if ((i % 2) > 0) {
            
            //if flags is not exists standard commands, exit
            if (![self.mgfSharedData.standardCommands containsObject:ns_argv]) {
                NSString *errorInfo = [NSString stringWithFormat:@"Option '%@' is not support, please confirm and retry!", ns_argv];
                [DebugLog showDebugLog:errorInfo withDebugLevel:Error];
                [self mgf_invokeDelegate:nil withFinished:FALSE withObject:nil];
            }
            
            [passed_command_flags_ addObject:ns_argv];
        }else {
            [passed_values_ addObject:ns_argv];
        }
    }
    
    //remove the coderesign path arguments
    [passed_values_ removeObjectAtIndex:0];
    
    //if values number is not equals to flags number, exit
    if (passed_command_flags_.count != passed_values_.count) {
        [DebugLog showDebugLog:@"Missed arguments for options" withDebugLevel:Error];
        [self mgf_invokeDelegate:nil withFinished:FALSE withObject:nil];
    }
    
    //save arguments values and flags to sharedData model, and show log
    self.mgfSharedData.crossedArguments  = [NSDictionary dictionaryWithObjects:passed_values_ forKeys:passed_command_flags_];
    [DebugLog showDebugLog:self.mgfSharedData.crossedArguments withDebugLevel:Debug];
    
    /**
     * Check passed arguments if valid
     *
     */
    [self.mgfSharedData.crossedArguments enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *_key      = (NSString *)key;
        NSString *_value    = (NSString *)obj;
        if ([_key isEqualToString:minus_d]) {
            if (![_value.pathExtension.lowercaseString isEqualToString:@"ipa"]) {
                [DebugLog showDebugLog:@"ipa path is not input or file type is not right, please confirm and retry!" withDebugLevel:Error];
                [self mgf_invokeDelegate:nil withFinished:FALSE withObject:nil];
            }
        }else if ([_key isEqualToString:minus_p] || [_key isEqualToString:minus_ex] || [_key isEqualToString:minus_wp] || [_key isEqualToString:minus_se]) {
            if (![_value.pathExtension.lowercaseString isEqualToString:@"mobileprovision"]) {
                [DebugLog showDebugLog:@"mobileprovision is not put or file type is not right, please confirm and retry!" withDebugLevel:Error];
                [self mgf_invokeDelegate:nil withFinished:FALSE withObject:nil];
            }
        }else if ([_key isEqualToString:minus_cer]) {
            if (_value.length == 0) {
                [DebugLog showDebugLog:@"certificate index is empty, please confirm and retry!" withDebugLevel:Error];
                [self mgf_invokeDelegate:nil withFinished:FALSE withObject:nil];
            }
        }else if ([_key isEqualToString:minus_py]) {
            if (![_value.pathExtension.lowercaseString isEqualToString:@"py"]) {
                [DebugLog showDebugLog:@"python scripy is empty please confirm and retry!" withDebugLevel:Error];
                [self mgf_invokeDelegate:nil withFinished:FALSE withObject:nil];
            }
            self.mgfSharedData.isResignAndDecode = TRUE;
            [DebugLog showDebugLog:@"You will do resign and decode icon action" withDebugLevel:Debug];
        }
    }];
    
    NSString *sourcePath = self.mgfSharedData.crossedArguments[minus_d];
    NSArray *destinationPathComponents = [sourcePath pathComponents];
    NSString *destinationPath = @"";
    
    for (int i = 0; i < ([destinationPathComponents count]-1); i++) {
        destinationPath = [destinationPath stringByAppendingPathComponent:[destinationPathComponents objectAtIndex:i]];
    }
    NSString *_tempPath = [destinationPath stringByAppendingPathComponent:@"temp"];
    [[NSFileManager defaultManager]createDirectoryAtPath:_tempPath withIntermediateDirectories:YES attributes:nil error:nil];
    self.mgfSharedData.commandPath = destinationPath;
    self.mgfSharedData.tempPath = _tempPath;
    
    [self mgf_invokeDelegate:self withFinished:TRUE withObject:nil];
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}


@end
