//
//  ModifyXcent.m
//  coderesign
//
//  Created by MiaoGuangfa on 10/12/15.
//  Copyright © 2015 MiaoGuangfa. All rights reserved.
//

#import "ModifyXcent.h"
#import "SharedData.h"
#import "DebugLog.h"

@interface ModifyXcent ()


@end

static ModifyXcent *_instance = NULL;

@implementation ModifyXcent

+ (ModifyXcent *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class]alloc]init];
    });
    
    return _instance;
}

- (void)ModifyXcentWithFinishedBlock:(void (^)(BOOL))finishedBlock
{
    
    NSString *_mainApp_xcent_path = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:@"archived-expanded-entitlements.xcent"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:_mainApp_xcent_path]) {
        //Modify ../xx.xcent
 
        [self rewriteXcentValue:_mainApp_xcent_path FromEntitlements:[SharedData sharedInstance].normalEntitlementsPlistPath];
    }
    
    if ([SharedData sharedInstance].isSupportWatchKitExtension) {
        NSString *_extension_xcent_path = [[SharedData sharedInstance].watchKitExtensionPath stringByAppendingPathComponent:@"archived-expanded-entitlements.xcent"];
        if([[NSFileManager defaultManager] fileExistsAtPath:_extension_xcent_path]) {
            //Modify ../appex/xx.exent
            [self rewriteXcentValue:_extension_xcent_path FromEntitlements:[SharedData sharedInstance].watchKitExtensionEntitlementsPlistPath];
        }
    }
    
    if ([SharedData sharedInstance].isSupportExtensionEntitlements) {
        NSString *_extension_entitlements_path = [SharedData sharedInstance].extensionEntitlementsPath;
        [self rewriteXcentValue:_extension_entitlements_path FromEntitlements:[SharedData sharedInstance].watchKitExtensionEntitlementsPlistPath];
    }
    
    
    if ([SharedData sharedInstance].isSupportWatchKitApp) {
        NSString *_watchkitApp_xcent_path = [[SharedData sharedInstance].watchKitAppPath stringByAppendingPathComponent:@"archived-expanded-entitlements.xcent"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:_watchkitApp_xcent_path]) {
            //Modify ../appex/xx.app/xx.xcent
            [self rewriteXcentValue:_watchkitApp_xcent_path FromEntitlements:[SharedData sharedInstance].watchKitAppEntitlementsPlistPath];
        }
    }
    
    finishedBlock(TRUE);
}

- (void) rewriteXcentValue:(NSString *)xcentFilePath FromEntitlements:(NSString *)entitlementsFilepath {
    if (xcentFilePath == nil || entitlementsFilepath == nil) {
        return;
    }
    
    NSDictionary *_yourEntitlementsDictionary = [[NSDictionary alloc]initWithContentsOfFile:entitlementsFilepath];
    NSMutableDictionary *_xcentDictionary = [[NSMutableDictionary alloc]initWithContentsOfFile:xcentFilePath];
    
    [_xcentDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        id _your_value = [_yourEntitlementsDictionary objectForKey:key];
        if (_your_value != nil) {
            [_xcentDictionary setObject:_your_value forKey:key];
        }/*else{
            *stop = YES;
            [DebugLog showDebugLog:@"Nil value is founded from your entitlements, so can't rewrite it for xcent file, please check it" withDebugLevel:Error];
            exit(0);
        }*/
    }];
    
    [_xcentDictionary writeToFile:xcentFilePath atomically:YES];
}

@end
