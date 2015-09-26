//
//  replaceMobileprovision.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/17/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "replaceMobileprovision.h"
#import "SharedData.h"
#import "DebugLog.h"
#import "parseAppInfo.h"

@interface replaceMobileprovision ()

@property (nonatomic, strong) NSTask *provisioningTask;

- (void)checkProvisioning:(NSTimer *)timer;

@end

static replaceMobileprovision *_instance = NULL;

@implementation replaceMobileprovision

+ (replaceMobileprovision *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class]alloc]init];
    });
    
    return _instance;
}

- (void)replace {
    if (![SharedData sharedInstance].isOnlyDecodeIcon) {
        [DebugLog showDebugLog:@"############################################################################ Replace mobile provision..." withDebugLevel:Info];
    }
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[SharedData sharedInstance].workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            [SharedData sharedInstance].appPath = [[[SharedData sharedInstance].workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
            
            if (![SharedData sharedInstance].isOnlyDecodeIcon) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:[[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
                    [DebugLog showDebugLog:@"Found embedded.mobileprovision, deleting." withDebugLevel:Info];
                    
                    [[NSFileManager defaultManager] removeItemAtPath:[[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] error:nil];
                }
            }
            
            break;
        }
    }
    
    if (![SharedData sharedInstance].isOnlyDecodeIcon) {
        NSString *targetPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
        
        _provisioningTask = [[NSTask alloc] init];
        [_provisioningTask setLaunchPath:@"/bin/cp"];
        [_provisioningTask setArguments:[NSArray arrayWithObjects:[SharedData sharedInstance].crossedArguments[minus_p], targetPath, nil]];
        
        [_provisioningTask launch];
        
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkProvisioning:) userInfo:nil repeats:TRUE];
    }else {
        //only do parse app info and decompress icon png
        
        NSString *infoPlistPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"Info.plist"];
        [[parseAppInfo sharedInstance]parse:infoPlistPath];
        
        [[NSFileManager defaultManager] removeItemAtPath:[SharedData sharedInstance].workingPath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[SharedData sharedInstance].tempPath error:nil];
        
        [DebugLog showDebugLog:AllDone];
        exit(0);
    }
}

- (void)checkProvisioning:(NSTimer *)timer {
    if ([_provisioningTask isRunning] == 0) {
        [timer invalidate];
        _provisioningTask = nil;
        
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[SharedData sharedInstance].workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
        
        for (NSString *file in dirContents) {
            if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
                [SharedData sharedInstance].appPath = [[[SharedData sharedInstance].workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
                if ([[NSFileManager defaultManager] fileExistsAtPath:[[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
                    
                    BOOL identifierOK = FALSE;
                    NSString *identifierInProvisioning = @"";
                    
                    NSString *embeddedProvisioning = [NSString stringWithContentsOfFile:[[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] encoding:NSASCIIStringEncoding error:nil];
                    NSArray* embeddedProvisioningLines = [embeddedProvisioning componentsSeparatedByCharactersInSet:
                                                          [NSCharacterSet newlineCharacterSet]];
                    
                    for (int i = 0; i <= [embeddedProvisioningLines count]; i++) {
                        if ([[embeddedProvisioningLines objectAtIndex:i] rangeOfString:@"application-identifier"].location != NSNotFound) {
                            
                            NSInteger fromPosition = [[embeddedProvisioningLines objectAtIndex:i+1] rangeOfString:@"<string>"].location + 8;
                            
                            NSInteger toPosition = [[embeddedProvisioningLines objectAtIndex:i+1] rangeOfString:@"</string>"].location;
                            
                            NSRange range;
                            range.location = fromPosition;
                            range.length = toPosition-fromPosition;
                            
                            NSString *fullIdentifier = [[embeddedProvisioningLines objectAtIndex:i+1] substringWithRange:range];
                            
                            NSArray *identifierComponents = [fullIdentifier componentsSeparatedByString:@"."];
                            
                            if ([[identifierComponents lastObject] isEqualTo:@"*"]) {
                                identifierOK = TRUE;
                            }
                            
                            for (int i = 1; i < [identifierComponents count]; i++) {
                                identifierInProvisioning = [identifierInProvisioning stringByAppendingString:[identifierComponents objectAtIndex:i]];
                                if (i < [identifierComponents count]-1) {
                                    identifierInProvisioning = [identifierInProvisioning stringByAppendingString:@"."];
                                }
                            }
                            break;
                        }
                    }
                    
                    NSLog(@"Mobileprovision identifier: %@",identifierInProvisioning);
                    
                    NSString *infoPlistPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"Info.plist"];
                    NSMutableDictionary *infoPlistDic = [[NSMutableDictionary alloc]initWithContentsOfFile:infoPlistPath];
                    
                    NSString *infoPlist = [NSString stringWithContentsOfFile:infoPlistPath encoding:NSASCIIStringEncoding error:nil];
                    if ([infoPlist rangeOfString:identifierInProvisioning].location != NSNotFound) {
                        NSLog(@"Identifiers match");
                        identifierOK = TRUE;
                    }
                    
                    if (identifierOK) {
                        [[parseAppInfo sharedInstance]parse:infoPlistPath];
                        [DebugLog showDebugLog:Pass];
                        
                    } else {
                        
                        [DebugLog showDebugLog:@"Product identifiers don't match, try to change Info.plist with specific app ID" withDebugLevel:Info];
                        [infoPlistDic setValue:identifierInProvisioning forKey:@"CFBundleIdentifier"];
                        [infoPlistDic writeToFile:infoPlistPath atomically:YES];
                        [[parseAppInfo sharedInstance]parse:infoPlistPath];
                    }
                    
                    [[NSNotificationCenter defaultCenter]postNotificationName:KCheckCPUNotification object:@(CPU_CHECK)];
                }else {
                    NSString * errorInfo = [NSString stringWithFormat:@"No embedded.mobileprovision file in %@", [SharedData sharedInstance].appPath];
                    [DebugLog showDebugLog:errorInfo withDebugLevel:Error];
                    exit(0);
                }
                break;
            }
        }
    }
}

@end
