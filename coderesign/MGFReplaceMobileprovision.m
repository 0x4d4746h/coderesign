//
//  replaceMobileprovision.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/17/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFReplaceMobileprovision.h"
#import "MGFParseAppInfo.h"
#import "MGFModifyXcent.h"

@interface MGFReplaceMobileprovision ()

@property (nonatomic, strong) NSTask *provisioningTask;
@property (nonatomic, assign) AppType currentAppType;
@property (nonatomic, copy) NSString *currentMobileProvisionPath;
@property (nonatomic, strong) MGFModifyXcent *mgfModifyXcent;

@end

@implementation MGFReplaceMobileprovision

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mgfModifyXcent = [[MGFModifyXcent alloc]init];
    }
    return self;
}

- (void)mgf_replaceMobileProvision
{
    
    [DebugLog showDebugLog:@"############################################################################ Replace mobile provision..." withDebugLevel:Debug];
    
    
    if (!self.mgfSharedData.isInHouseType) {
        
        dispatch_queue_t queue = dispatch_queue_create("update.mobileprovision.queue", DISPATCH_QUEUE_CONCURRENT);
        
        // Delete embedded.mobileprovision file from main.app
        [DebugLog showDebugLog:@"Found embedded.mobileprovision in main app, deleting..." withDebugLevel:Debug];
        [[NSFileManager defaultManager] removeItemAtPath:[self.mgfSharedData.appPath stringByAppendingPathComponent:kEmbedded_MobileProvision] error:nil];
        
        dispatch_async(queue, ^{
            [self __mgf_copyAndUpdateNewMobileProvisionFileForApp:MainApp];
        });
        
        //Delete embedded.mobileprovision file from appex
        if (self.mgfSharedData.isSupportWatchKitExtension) {
            [DebugLog showDebugLog:@"Found embedded.mobileprovision in watch kit extension, deleting..." withDebugLevel:Debug];
            [[NSFileManager defaultManager] removeItemAtPath:[self.mgfSharedData.watchKitExtensionPath stringByAppendingPathComponent:kEmbedded_MobileProvision] error:nil];
            dispatch_async(queue, ^{
                [self __mgf_copyAndUpdateNewMobileProvisionFileForApp:Extension];
            });
        }
        
        // Delete embedded.mobileprovision file from watch kit app in appex
        if (self.mgfSharedData.isSupportWatchKitApp) {
            [DebugLog showDebugLog:@"Found embedded.mobileprovision in watch kit app, deleting..." withDebugLevel:Debug];
            [[NSFileManager defaultManager] removeItemAtPath:[self.mgfSharedData.watchKitAppPath stringByAppendingPathComponent:kEmbedded_MobileProvision] error:nil];
            dispatch_async(queue, ^{
                [self __mgf_copyAndUpdateNewMobileProvisionFileForApp:WatchApp];
            });
        }
        
        if (self.mgfSharedData.isSupportSharedExtension) {
            [DebugLog showDebugLog:@"Found embedded.mobileprovision in sharedExtension, deleting..." withDebugLevel:Debug];
            [[NSFileManager defaultManager] removeItemAtPath:[self.mgfSharedData.sharedExtensionPath stringByAppendingPathComponent:kEmbedded_MobileProvision] error:nil];
            
            dispatch_async(queue, ^{
                [self __mgf_copyAndUpdateNewMobileProvisionFileForApp:SharedExtension];
            });
        }
        
        dispatch_barrier_async(queue, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self mgf_invokeDelegate:self withFinished:TRUE withObject:nil];
            });
        });
        
    }
}

#pragma private methods
- (void) __mgf_copyAndUpdateNewMobileProvisionFileForApp:(AppType)type{
    @synchronized(self) {
        
        NSRunLoop *currentRunloop = [NSRunLoop currentRunLoop];
        _currentAppType = type;
        
        _provisioningTask = [[NSTask alloc] init];
        [_provisioningTask setLaunchPath:@"/bin/cp"];
        
        NSString *targetPath;
        if (type == MainApp) {
            
            targetPath = [self.mgfSharedData.appPath stringByAppendingPathComponent:kEmbedded_MobileProvision];
            [_provisioningTask setArguments:[NSArray arrayWithObjects:self.mgfSharedData.crossedArguments[minus_p], targetPath, nil]];
            
        }else if (type == Extension) {
            targetPath = [self.mgfSharedData.watchKitExtensionPath stringByAppendingPathComponent:kEmbedded_MobileProvision];
            [_provisioningTask setArguments:[NSArray arrayWithObjects:self.mgfSharedData.crossedArguments[minus_ex], targetPath, nil]];
            
            
        }else if(type == WatchApp) {
            targetPath = [self.mgfSharedData.watchKitAppPath stringByAppendingPathComponent:kEmbedded_MobileProvision];
            [_provisioningTask setArguments:[NSArray arrayWithObjects:self.mgfSharedData.crossedArguments[minus_wp], targetPath, nil]];
            
        }else if (type == SharedExtension) {
            targetPath = [self.mgfSharedData.sharedExtensionPath stringByAppendingPathComponent:kEmbedded_MobileProvision];
            [_provisioningTask setArguments:[NSArray arrayWithObjects:self.mgfSharedData.crossedArguments[minus_se], targetPath, nil]];
            
        }
        
        _currentMobileProvisionPath = targetPath;
        
        [_provisioningTask launch];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(__mgf_checkProvisioning:) userInfo:nil repeats:TRUE];
        [currentRunloop run];
    }
}

- (void)__mgf_checkProvisioning:(NSTimer *)timer {
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
                    NSLog(@"------- fullIdentifier :  %@", fullIdentifier);
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
                
                infoPlistPath = [self.mgfSharedData.appPath stringByAppendingPathComponent:kInfo_plist];
                self.mgfSharedData.mainAppID = identifierInProvisioning;
                if (!identifierOK) {
                    [_mgfModifyXcent mgf_modifyXcentWithAppType:MainApp];
                }
            }else if (_currentAppType == Extension) {
                
                infoPlistPath = [self.mgfSharedData.watchKitExtensionPath stringByAppendingPathComponent:kInfo_plist];
                self.mgfSharedData.watchKitExtensionID = identifierInProvisioning;
                
                if (!identifierOK) {
                    [_mgfModifyXcent mgf_modifyXcentWithAppType:Extension];
                }
            }else if (_currentAppType == WatchApp) {
                
                infoPlistPath = [self.mgfSharedData.watchKitAppPath stringByAppendingPathComponent:kInfo_plist];
                self.mgfSharedData.watchKitAppID = identifierInProvisioning;
                if (!identifierOK) {
                    [self __mgf_modifyWatchKitExtensionInfoPlistForNSExtension];
                    [self __mgf_modifyWatchKitAppCompanionID];
                    [_mgfModifyXcent mgf_modifyXcentWithAppType:WatchApp];
                }
                
            }else if (_currentAppType == SharedExtension) {
                
                infoPlistPath = [self.mgfSharedData.sharedExtensionPath stringByAppendingPathComponent:kInfo_plist];
                self.mgfSharedData.sharedExtensionID = identifierInProvisioning;
                if (!identifierOK) {
                    [_mgfModifyXcent mgf_modifyXcentWithAppType:SharedExtension];
                }
            }
            
            NSMutableDictionary *infoPlistDic = [[NSMutableDictionary alloc]initWithContentsOfFile:infoPlistPath];
            NSString *infoPlist = [NSString stringWithContentsOfFile:infoPlistPath encoding:NSASCIIStringEncoding error:nil];
            if ([infoPlist rangeOfString:identifierInProvisioning].location != NSNotFound) {
                NSLog(@"Identifiers match");
                identifierOK = TRUE;
            }
            
            if (!identifierOK) {
                [DebugLog showDebugLog:@"IPA info.plist CFBundle identifier doesn't match with your mobile provision, try to change Info.plist with your specific app ID" withDebugLevel:Debug];
                [infoPlistDic setValue:identifierInProvisioning forKey:@"CFBundleIdentifier"];
                [infoPlistDic writeToFile:infoPlistPath atomically:YES];
            }
        }
    }
}

#pragma private method
- (void)__mgf_modifyWatchKitExtensionInfoPlistForNSExtension
{
    if (self.mgfSharedData.isSupportWatchKitExtension) {
        NSString *_watchKitExtensionInfoPlist = [[MGFSharedData sharedInstance].watchKitExtensionPath stringByAppendingPathComponent:kInfo_plist];
        NSMutableDictionary *_watchKitExtensionInfoPlistDic = [[NSMutableDictionary alloc]initWithContentsOfFile:_watchKitExtensionInfoPlist];
        
        
        NSDictionary *_nsExtensionAttributes = [_watchKitExtensionInfoPlistDic objectForKey:@"NSExtension"];
        if (_nsExtensionAttributes) {
            NSDictionary *_attribute = [_nsExtensionAttributes objectForKey:@"NSExtensionAttributes"];
            if (_attribute) {
                
                [_attribute setValue:[MGFSharedData sharedInstance].watchKitAppID forKey:@"WKAppBundleIdentifier"];
                [_nsExtensionAttributes setValue:_attribute forKey:@"NSExtensionAttributes"];
                [_watchKitExtensionInfoPlistDic setValue:_nsExtensionAttributes forKey:@"NSExtension"];
                
                [_watchKitExtensionInfoPlistDic writeToFile:_watchKitExtensionInfoPlist atomically:YES];
            }
        }
        NSLog(@"modifyWatchKitExtensionInfoPlistForNSExtension: %@", _watchKitExtensionInfoPlistDic);
    }
    
    
}

- (void)__mgf_modifyWatchKitAppCompanionID {
    if (self.mgfSharedData.isSupportWatchKitApp) {
        NSString *_watchKitAppInfoPlist = [[MGFSharedData sharedInstance].watchKitAppPath stringByAppendingPathComponent:kInfo_plist];
        NSMutableDictionary *_watchKitAppInfoPlistDic = [[NSMutableDictionary alloc]initWithContentsOfFile:_watchKitAppInfoPlist];
        
        [_watchKitAppInfoPlistDic setValue:[MGFSharedData sharedInstance].mainAppID forKey:@"WKCompanionAppBundleIdentifier"];
        
        [_watchKitAppInfoPlistDic writeToFile:_watchKitAppInfoPlist atomically:YES];
        
         NSLog(@"modifyWatchKitAppCompanionID: %@", _watchKitAppInfoPlist);
    }
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

@end
