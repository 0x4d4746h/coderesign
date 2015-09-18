//
//  parseAppInfo.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/17/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "parseAppInfo.h"
#import "DebugLog.h"
#import "SharedData.h"
#import "decompressIcon.h"


static parseAppInfo *_instance = NULL;

@implementation parseAppInfo

+ (parseAppInfo *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class]alloc]init];
    });
    
    return _instance;
}

- (void)parse:(NSString *)infoPlistPath
{
    NSDictionary *infoPlist_dictionary = [[NSDictionary alloc]initWithContentsOfFile:infoPlistPath];
    
    if (!infoPlist_dictionary) {
        [DebugLog showDebugLog:@"Can't parse Info.plist for this app" withDebugLevel:Error];
        return;
    }
    
    NSString *_appName          = [infoPlist_dictionary objectForKey:@"CFBundleDisplayName"];
    NSString *_packageName      = [infoPlist_dictionary objectForKey:@"CFBundleIdentifier"];
    NSString *_iconName         = [infoPlist_dictionary objectForKey:@"CFBundleIconFile"];
    NSString *_version          = [infoPlist_dictionary objectForKey:@"CFBundleVersion"];
    NSString *_minSDKVersion    = [infoPlist_dictionary objectForKey:@"MinimumOSVersion"];
    NSString *_sdkVersion       = [infoPlist_dictionary objectForKey:@"DTPlatformVersion"];
    NSString *_cfBundleExecutable = [infoPlist_dictionary objectForKey:@"CFBundleExecutable"];
    
    
    NSString *normal_icon = @"";
    if (_iconName != nil) {

        NSString *icon_file   = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:_iconName];
        NSData *_icon_data = [[NSFileManager defaultManager]contentsAtPath:icon_file];
        NSString *destinationPath = [SharedData sharedInstance].commandPath;
        
        NSString *outputPath = [destinationPath stringByAppendingPathComponent:@"Icon-compressed.png"];
        [[NSFileManager defaultManager]createFileAtPath:outputPath contents:_icon_data attributes:nil];
        
        normal_icon = [destinationPath stringByAppendingPathComponent:@"icon.png"];
        [decompressIcon convertEncryptedImageDataToNormal:outputPath withNewFilePath:normal_icon withPy:[SharedData sharedInstance].crossedArguments[minus_py]];
    }
    
    NSDictionary *_appInfo = @{
                               @"packageName"       :   [self nilToString:_packageName],
                               @"appName"           :   [self nilToString:_appName],
                               @"icon"              :   [self nilToString:normal_icon],
                               @"version"           :   [self nilToString:_version],
                               @"minOSVersion"      :   [self nilToString:_minSDKVersion],
                               @"OSVersion"         :   [self nilToString:_sdkVersion],
                               @"CFBuldleExecutable":   [self nilToString:_cfBundleExecutable]
                               };
    NSData *objData = [NSJSONSerialization dataWithJSONObject:_appInfo options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:objData encoding:NSUTF8StringEncoding];
    
    NSString *_resutl = [@"<appInfo>" stringByAppendingFormat:@"%@</appInfo>", jsonString];
    [DebugLog showDebugLog:_resutl withDebugLevel:Info];
}

- (id)nilToString:(id)object {
    if (object == nil) {
        return @"";
    }
    return object;
}

@end
