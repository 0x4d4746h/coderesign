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
            
            NSString *extensionPluginPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:kPlugIns];
            if ([[NSFileManager defaultManager]fileExistsAtPath:extensionPluginPath]) {
                NSArray *_extensionFiles = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:extensionPluginPath error:nil];
                for (NSString *_extensionFile in _extensionFiles) {
                    NSString *_extensionName = [[_extensionFile pathExtension]lowercaseString];
                    if ([_extensionName isEqualToString:@"appex"]) {
                        extensionPluginPath = [extensionPluginPath stringByAppendingPathComponent:_extensionFile];
                        [SharedData sharedInstance].extensionPath = extensionPluginPath;
                    }
                }
                
            }
            
            if (![SharedData sharedInstance].isOnlyDecodeIcon) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:[[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
                    [DebugLog showDebugLog:@"Found embedded.mobileprovision in main app, deleting..." withDebugLevel:Info];
                    
                    [[NSFileManager defaultManager] removeItemAtPath:[[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] error:nil];
                }
                
                if ([SharedData sharedInstance].extensionPath !=NULL && [[NSFileManager defaultManager]fileExistsAtPath:[[SharedData sharedInstance].extensionPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
                    [DebugLog showDebugLog:@"Found embedded.mobileprovision in extension app, deleting..." withDebugLevel:Info];
                    [[NSFileManager defaultManager] removeItemAtPath:[[SharedData sharedInstance].extensionPath stringByAppendingPathComponent:@"embedded.mobileprovision"] error:nil];
                }
            }
            
            break;
        }
    }
    
    
    if (![SharedData sharedInstance].isOnlyDecodeIcon) {
        [self _copyAndUpdateNewMobileProvisionFile:kMainApp];
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

- (void) _copyAndUpdateNewMobileProvisionFile:(NSString *)appType {
    
    _provisioningTask = [[NSTask alloc] init];
    [_provisioningTask setLaunchPath:@"/bin/cp"];
    
    NSString *targetPath;
    if ([appType isEqualToString:kMainApp]) {
        targetPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
        [SharedData sharedInstance].currentAppType = kMainApp;
        [_provisioningTask setArguments:[NSArray arrayWithObjects:[SharedData sharedInstance].crossedArguments[minus_p], targetPath, nil]];
        
    }else if ([appType isEqualToString:kExtensionApp]) {
        targetPath = [[SharedData sharedInstance].extensionPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
        [SharedData sharedInstance].currentAppType = kExtensionApp;
        [_provisioningTask setArguments:[NSArray arrayWithObjects:[SharedData sharedInstance].crossedArguments[minus_ex], targetPath, nil]];
    }
    
    //if ([[NSFileManager defaultManager]fileExistsAtPath:targetPath]) {
        [_provisioningTask launch];
        
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkProvisioning:) userInfo:nil repeats:TRUE];
//    }else {
//        [[NSNotificationCenter defaultCenter]postNotificationName:KCheckCPUNotification object:@(CPU_CHECK)];
//    }
}

- (void)checkProvisioning:(NSTimer *)timer {
    if ([_provisioningTask isRunning] == 0) {
        [timer invalidate];
        _provisioningTask = nil;
        
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[SharedData sharedInstance].workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
        
        for (NSString *file in dirContents) {
            if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
                [SharedData sharedInstance].appPath = [[[SharedData sharedInstance].workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
                
                NSString *_mobileprovisionPath;
                if ([[SharedData sharedInstance].currentAppType isEqualToString:kExtensionApp]) {
                    _mobileprovisionPath = [[SharedData sharedInstance].extensionPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
                }else if ([[SharedData sharedInstance].currentAppType isEqualToString:kMainApp]) {
                    _mobileprovisionPath =[[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
                }
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:_mobileprovisionPath]) {
                    
                    BOOL identifierOK = FALSE;
                    NSString *identifierInProvisioning = @"";
                    
                    NSString *embeddedProvisioning;
                    if ([[SharedData sharedInstance].currentAppType isEqualToString:kExtensionApp]) {
                        embeddedProvisioning = [NSString stringWithContentsOfFile:[[SharedData sharedInstance].extensionPath stringByAppendingPathComponent:@"embedded.mobileprovision"] encoding:NSASCIIStringEncoding error:nil];
                    }else if ([[SharedData sharedInstance].currentAppType isEqualToString:kMainApp]) {
                        embeddedProvisioning = [NSString stringWithContentsOfFile:[[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] encoding:NSASCIIStringEncoding error:nil];
                    }
                    
                    
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
                    NSString *infoPlistPath;
                    if ([[SharedData sharedInstance].currentAppType isEqualToString:kMainApp]) {
                       infoPlistPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"Info.plist"];
                    }else if ([[SharedData sharedInstance].currentAppType isEqualToString:kExtensionApp]) {
                        infoPlistPath = [[SharedData sharedInstance].extensionPath stringByAppendingPathComponent:@"Info.plist"];
                    }
                    
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
                    
                    //if need to update app group, then do it
                    if ([SharedData sharedInstance].appGroups) {
                        NSString *archivedExpandedEntitlementsPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"archived-expanded-entitlements.xcent"];
                        NSMutableDictionary *_appgroupsDictionary = [[NSMutableDictionary alloc]initWithContentsOfFile:archivedExpandedEntitlementsPath];
                        [_appgroupsDictionary setObject:[SharedData sharedInstance].appGroups forKey:@"com.apple.security.application-groups"];
                        [_appgroupsDictionary writeToFile:archivedExpandedEntitlementsPath atomically:YES];
                        [SharedData sharedInstance].appGroups = nil;
                    }
                    
                    if ([[SharedData sharedInstance].currentAppType isEqualToString:kMainApp]) {
                        [self _copyAndUpdateNewMobileProvisionFile:kExtensionApp];
                        
                         [[NSNotificationCenter defaultCenter]postNotificationName:KCheckCPUNotification object:@(CPU_CHECK)];
                    }
                   
                }else {
                    if ([[SharedData sharedInstance].currentAppType isEqualToString:kExtensionApp]) {
                        return;
                    }
                    NSString * errorInfo = [NSString stringWithFormat:@"No embedded.mobileprovision file in %@", _mobileprovisionPath];
                    [DebugLog showDebugLog:errorInfo withDebugLevel:Error];
                    exit(0);
                }
                break;
            }
        }
    }
}

@end
