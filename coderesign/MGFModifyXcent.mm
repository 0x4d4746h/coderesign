//
//  ModifyXcent.m
//  coderesign
//
//  Created by MiaoGuangfa on 10/12/15.
//  Copyright © 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFModifyXcent.h"



@implementation MGFModifyXcent

- (void)mgf_modifyXcentWithAppType:(AppType)type
{
    if (type == MainApp) {
        NSString *_mainApp_xcent_path = [self.mgfSharedData.appPath stringByAppendingPathComponent:@"archived-expanded-entitlements.xcent"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:_mainApp_xcent_path]) {
            //Modify ../xx.xcent
            
            [self __mgf_rewriteXcentValue:_mainApp_xcent_path FromEntitlements:self.mgfSharedData.normalEntitlementsPlistPath];
        }
    }
    
    if (type == Extension && self.mgfSharedData.isSupportWatchKitExtension) {
        NSString *_extension_xcent_path = [self.mgfSharedData.watchKitExtensionPath stringByAppendingPathComponent:@"archived-expanded-entitlements.xcent"];
        if([[NSFileManager defaultManager] fileExistsAtPath:_extension_xcent_path]) {
            //Modify ../appex/xx.exent
            [self __mgf_rewriteXcentValue:_extension_xcent_path FromEntitlements:self.mgfSharedData.watchKitExtensionEntitlementsPlistPath];
        }
    }
    
    
    if (type == WatchApp &&self.mgfSharedData.isSupportWatchKitApp) {
        NSString *_watchkitApp_xcent_path = [self.mgfSharedData.watchKitAppPath stringByAppendingPathComponent:@"archived-expanded-entitlements.xcent"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:_watchkitApp_xcent_path]) {
            //Modify ../appex/xx.app/xx.xcent
            [self __mgf_rewriteXcentValue:_watchkitApp_xcent_path FromEntitlements:self.mgfSharedData.watchKitAppEntitlementsPlistPath];
        }
    }
    
    if (type == SharedExtension &&self.mgfSharedData.isSupportSharedExtension) {
        NSString *_sharedExtension_xcent_path = [self.mgfSharedData.sharedExtensionPath stringByAppendingPathComponent:@"archived-expanded-entitlements.xcent"];
        if ([[NSFileManager defaultManager]fileExistsAtPath:_sharedExtension_xcent_path]) {
            [self __mgf_rewriteXcentValue:_sharedExtension_xcent_path FromEntitlements:self.mgfSharedData.sharedExtensionEntitlementsPlistPath];
        }
    }
    [self mgf_invokeDelegate:self withFinished:TRUE withObject:nil];
}

#pragma private method
- (void)__mgf_rewriteXcentValue:(NSString *)xcentFilePath FromEntitlements:(NSString *)entitlementsFilepath {
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
