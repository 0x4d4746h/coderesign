//
//  parsePlayload.m
//  coderesign
//
//  Created by MiaoGuangfa on 10/10/15.
//  Copyright © 2015 MiaoGuangfa. All rights reserved.
//

#import "parsePlayload.h"
#import "SharedData.h"
#import "securityEncodeDecodeMobileProvision.h"

@interface parsePlayload ()

@end

static parsePlayload *_instance = NULL;

@implementation parsePlayload

+ (parsePlayload *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class]alloc]init];
    });
    
    return _instance;
}

- (void)parsePlayloadWithFinishedBlock:(void (^)(BOOL))finishedBlock
{
    NSArray *playloadFileContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[SharedData sharedInstance].workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
    for (NSString *file in playloadFileContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            [SharedData sharedInstance].appPath = [[[SharedData sharedInstance].workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
            
            /**
             * Check if support App Group
             */
            NSString *appMobileProvision = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:appMobileProvision]) {
                NSString *embeddedProvisioning = [NSString stringWithContentsOfFile:appMobileProvision encoding:NSASCIIStringEncoding error:nil];
                NSArray* embeddedProvisioningLines = [embeddedProvisioning componentsSeparatedByCharactersInSet:
                                                      [NSCharacterSet newlineCharacterSet]];
                
                for (int i = 0; i < [embeddedProvisioningLines count]; i++) {
                    if ([[embeddedProvisioningLines objectAtIndex:i] rangeOfString:@"com.apple.security.application-groups"].location != NSNotFound) {
                        
                        // Find it
                        [SharedData sharedInstance].isSupportAppGroup = TRUE;
                    }
                }
            }
            
            /**
             * Check if Frameworks exists or not.
             */
            NSString *frameworksDirPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:kFrameworksDirName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:frameworksDirPath]) {
                
                NSArray *frameworksContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:frameworksDirPath error:nil];
                for (NSString *frameworkFile in frameworksContents) {
                    NSString *extension = [[frameworkFile pathExtension] lowercaseString];
                    if ([extension isEqualTo:@"framework"] || [extension isEqualTo:@"dylib"]) {
                        [[SharedData sharedInstance].swiftFrameworks addObject:[frameworksDirPath stringByAppendingPathComponent:frameworkFile]];
                    }
                }
                
                // ../Frameworks/
                [SharedData sharedInstance].swiftFrameworksPath = frameworksDirPath;
                [SharedData sharedInstance].isSupportSwift = TRUE;
            }
            
            /**
             * Check if PlugIns exists or not.
             */
            //PlugIns
            NSString *extensionPluginPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:kPlugIns];
            if ([[NSFileManager defaultManager]fileExistsAtPath:extensionPluginPath]) {
                [SharedData sharedInstance].plugInsPath = extensionPluginPath;
                
                NSArray *_extensionFiles = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:extensionPluginPath error:nil];
                for (NSString *_extensionFile in _extensionFiles) {
                    NSString *_extensionName = [[_extensionFile pathExtension]lowercaseString];
                    if ([_extensionName isEqualToString:@"appex"]) {
                        
                        // ../PlugIns/xxx.appex
                        extensionPluginPath = [extensionPluginPath stringByAppendingPathComponent:_extensionFile];
                        [SharedData sharedInstance].watchKitExtensionPath = extensionPluginPath;
                        [SharedData sharedInstance].isSupportWatchKitExtension = TRUE;
                        
                        /**
                         * Check if watchkit app exists in appex
                         */
                        NSArray *appexFiles = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:extensionPluginPath error:nil];
                        for(NSString *_watchKitAppFile in appexFiles) {
                            if ([[[_watchKitAppFile pathExtension] lowercaseString] isEqualToString:@"app"]) {
                                
                                // ../PlugIns/xx.appex/xx.app
                                [SharedData sharedInstance].watchKitAppPath = [extensionPluginPath stringByAppendingPathComponent:_watchKitAppFile];
                                [SharedData sharedInstance].isSupportWatchKitApp = TRUE;
                            }
                            
                            //Check extension entitlements if exists or not.
                            if ([[[_watchKitAppFile pathExtension] lowercaseString] isEqualToString:@"entitlements"]) {
                                
                                // ../PlugIns/xx.appex/xx.entitlements
                                [SharedData sharedInstance].extensionEntitlementsPath = [extensionPluginPath stringByAppendingPathComponent:_watchKitAppFile];
                                [SharedData sharedInstance].isSupportExtensionEntitlements = YES;
                            }
                        }
                        
                        break;
                    }
                }
            }
        }
        break;
    }
    
    //check if in-house type
    [[securityEncodeDecodeMobileProvision sharedInstance]checkIfInHouseType:[[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] withBlock:^(BOOL isFinished, EntitlementsType type) {
        finishedBlock(TRUE);
    }];
}

@end
