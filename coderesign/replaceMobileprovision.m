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
#import "parsePlayload.h"

typedef void(^CopyFinishedBlock)(BOOL isFinished);

@interface replaceMobileprovision ()

@property (nonatomic, strong) NSTask *provisioningTask;
@property (nonatomic, copy) CopyFinishedBlock copyFinishedBlock;
@property (nonatomic, assign) AppType currentAppType;
@property (nonatomic, copy) NSString *currentMobileProvisionPath;

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

- (void)replaceWithFinishedBlock:(void (^)(BOOL))finishedBlock
{
    if (![SharedData sharedInstance].isOnlyDecodeIcon) {
        [DebugLog showDebugLog:@"############################################################################ Replace mobile provision..." withDebugLevel:Debug];
    }
    // parse play load
    [[parsePlayload sharedInstance]parsePlayloadWithFinishedBlock:^(BOOL isFinished) {
        if (![SharedData sharedInstance].isInHouseType) {
            
            
            if (![SharedData sharedInstance].isOnlyDecodeIcon) {
                
                // Delete embedded.mobileprovision file from main.app
                if ([[NSFileManager defaultManager] fileExistsAtPath:[[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
                    [DebugLog showDebugLog:@"Found embedded.mobileprovision in main app, deleting..." withDebugLevel:Debug];
                    
                    [[NSFileManager defaultManager] removeItemAtPath:[[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] error:nil];
                }
                
                //Delete embedded.mobileprovision file from appex
                if ([SharedData sharedInstance].isSupportWatchKitExtension) {
                    [DebugLog showDebugLog:@"Found embedded.mobileprovision in watch kit extension, deleting..." withDebugLevel:Debug];
                    [[NSFileManager defaultManager] removeItemAtPath:[[SharedData sharedInstance].watchKitExtensionPath stringByAppendingPathComponent:@"embedded.mobileprovision"] error:nil];
                }
                
                // Delete embedded.mobileprovision file from watch kit app in appex
                if ([SharedData sharedInstance].isSupportWatchKitApp) {
                    [DebugLog showDebugLog:@"Found embedded.mobileprovision in watch kit app, deleting..." withDebugLevel:Debug];
                    [[NSFileManager defaultManager] removeItemAtPath:[[SharedData sharedInstance].watchKitAppPath stringByAppendingPathComponent:@"embedded.mobileprovision"] error:nil];
                }
            }
        }
        
        if (![SharedData sharedInstance].isOnlyDecodeIcon) {
            
            if (![SharedData sharedInstance].isInHouseType) {
                __weak typeof(&*self)  weakSelf = self;
                dispatch_group_t copyMobileProvisionGroup = dispatch_group_create();
                
                dispatch_group_enter(copyMobileProvisionGroup);
                [self _copyAndUpdateNewMobileProvisionFileForApp:MainApp WithFinishedBlock:^(BOOL isFinished) {
                    
                    //if support watch kit extension, then copy your mobile provision file to specific path.
                    if (isFinished && [SharedData sharedInstance].isSupportWatchKitExtension) {
                        [weakSelf _copyAndUpdateNewMobileProvisionFileForApp:Extension WithFinishedBlock:^(BOOL isFinished) {
                            
                            // if support watch kit app, then copy your mobile provision file to specific path.
                            if (isFinished && [SharedData sharedInstance].isSupportWatchKitApp) {
                                [weakSelf _copyAndUpdateNewMobileProvisionFileForApp:WatchApp WithFinishedBlock:^(BOOL isFinished) {
                                    
                                    
                                    dispatch_group_leave(copyMobileProvisionGroup);
                                }];
                            }else{
                                dispatch_group_leave(copyMobileProvisionGroup);
                            }
                        }];
                    }else{
                        dispatch_group_leave(copyMobileProvisionGroup);
                    }
                }];
                
                dispatch_group_notify(copyMobileProvisionGroup, dispatch_get_main_queue(), ^{
                    finishedBlock(TRUE);
                });
            }else{
                NSString *_main_app_infoPlistPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"Info.plist"];
                [[parseAppInfo sharedInstance]parse:_main_app_infoPlistPath withAppType:MainApp];
                
                if ([SharedData sharedInstance].isSupportWatchKitExtension) {
                    NSString *_extension_infoPlistPath = [[SharedData sharedInstance].watchKitExtensionPath stringByAppendingPathComponent:@"Info.plist"];
                    [[parseAppInfo sharedInstance]parse:_extension_infoPlistPath withAppType:Extension];
                }
                if ([SharedData sharedInstance].isSupportWatchKitApp) {
                    NSString *_watchkitapp_infoPlistPath = [[SharedData sharedInstance].watchKitAppPath stringByAppendingPathComponent:@"Info.plist"];
                    [[parseAppInfo sharedInstance]parse:_watchkitapp_infoPlistPath withAppType:WatchApp];
                }
                finishedBlock(TRUE);
            }
            
        }else {
            //only do parse app info and decompress icon png
            NSString *infoPlistPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"Info.plist"];
            [[parseAppInfo sharedInstance]parse:infoPlistPath withAppType:MainApp];
            
            [[NSFileManager defaultManager] removeItemAtPath:[SharedData sharedInstance].workingPath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[SharedData sharedInstance].tempPath error:nil];
            
            [DebugLog showDebugLog:AllDone];
            finishedBlock(TRUE);
            exit(0);
        }
    }];
}

- (void) _copyAndUpdateNewMobileProvisionFileForApp:(AppType)type WithFinishedBlock:(CopyFinishedBlock)copyFinishedBlock {
    
    _copyFinishedBlock = copyFinishedBlock;
    _currentAppType = type;
    
    _provisioningTask = [[NSTask alloc] init];
    [_provisioningTask setLaunchPath:@"/bin/cp"];
    
    NSString *targetPath;
    if (type == MainApp) {
        
        targetPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
        [_provisioningTask setArguments:[NSArray arrayWithObjects:[SharedData sharedInstance].crossedArguments[minus_p], targetPath, nil]];
        
    }else if (type == Extension) {
        
        targetPath = [[SharedData sharedInstance].watchKitExtensionPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
        [_provisioningTask setArguments:[NSArray arrayWithObjects:[SharedData sharedInstance].crossedArguments[minus_ex], targetPath, nil]];
        
    }else if(type == WatchApp) {
        
        targetPath = [[SharedData sharedInstance].watchKitAppPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
        [_provisioningTask setArguments:[NSArray arrayWithObjects:[SharedData sharedInstance].crossedArguments[minus_wp], targetPath, nil]];
        
    }
    
    _currentMobileProvisionPath = targetPath;
    
    [_provisioningTask launch];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkProvisioning:) userInfo:nil repeats:TRUE];
}

- (void)checkProvisioning:(NSTimer *)timer {
    if ([_provisioningTask isRunning] == 0) {
        [timer invalidate];
        _provisioningTask = nil;
        
        //check the replaced embedded.mobileprovision file
        if ([[NSFileManager defaultManager] fileExistsAtPath:_currentMobileProvisionPath]) {
            
            BOOL identifierOK = FALSE;
            NSString *identifierInProvisioning = @"";
            
            NSString *embeddedProvisioning = [NSString stringWithContentsOfFile:_currentMobileProvisionPath encoding:NSASCIIStringEncoding error:nil];
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
            
            
            /**
             * check the CFBundleIdentifier for Info.plist, if not match, then change this value with your app id
             */
            NSString *infoPlistPath;
            if (_currentAppType == MainApp) {
                
                infoPlistPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"Info.plist"];
                [SharedData sharedInstance].mainAppID = identifierInProvisioning;
                
            }else if (_currentAppType == Extension) {
                
                infoPlistPath = [[SharedData sharedInstance].watchKitExtensionPath stringByAppendingPathComponent:@"Info.plist"];
                
                
            }else if (_currentAppType == WatchApp) {
                
                infoPlistPath = [[SharedData sharedInstance].watchKitAppPath stringByAppendingPathComponent:@"Info.plist"];
                [SharedData sharedInstance].watchKitAppID = identifierInProvisioning;
            }
            
            NSMutableDictionary *infoPlistDic = [[NSMutableDictionary alloc]initWithContentsOfFile:infoPlistPath];
            NSString *infoPlist = [NSString stringWithContentsOfFile:infoPlistPath encoding:NSASCIIStringEncoding error:nil];
            if ([infoPlist rangeOfString:identifierInProvisioning].location != NSNotFound) {
                NSLog(@"Identifiers match");
                identifierOK = TRUE;
            }
            
            if (identifierOK) {
                
                [[parseAppInfo sharedInstance]parse:infoPlistPath withAppType:_currentAppType];
                [DebugLog showDebugLog:Pass];
                _copyFinishedBlock(TRUE);
                
            } else {
                
                [DebugLog showDebugLog:@"IPA info.plist CFBundle identifier doesn't match with your mobile provision, try to change Info.plist with your specific app ID" withDebugLevel:Debug];
                [infoPlistDic setValue:identifierInProvisioning forKey:@"CFBundleIdentifier"];
                [infoPlistDic writeToFile:infoPlistPath atomically:YES];
                [[parseAppInfo sharedInstance]parse:infoPlistPath withAppType:_currentAppType];
                _copyFinishedBlock(TRUE);
            }
        }
    }
}

@end
