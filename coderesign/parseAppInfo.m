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
    
    NSString *icon_file         = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:_iconName];
    
    NSData *_icon_data = [[NSFileManager defaultManager]contentsAtPath:icon_file];
    NSString *sourcePath = [SharedData sharedInstance].crossedArguments[minus_d];
    NSArray *destinationPathComponents = [sourcePath pathComponents];
    NSString *destinationPath = @"";
    
    for (int i = 0; i < ([destinationPathComponents count]-1); i++) {
        destinationPath = [destinationPath stringByAppendingPathComponent:[destinationPathComponents objectAtIndex:i]];
    }
    
    NSString *outputPath = [destinationPath stringByAppendingPathComponent:@"Icon-compressed.png"];
    [[NSFileManager defaultManager]createFileAtPath:outputPath contents:_icon_data attributes:nil];

    NSString *normal = [destinationPath stringByAppendingPathComponent:@"icon.png"];
    [decompressIcon convertEncryptedImageDataToNormal:outputPath withNewFilePath:normal withPy:[SharedData sharedInstance].crossedArguments[minus_py]];
    NSDictionary *_appInfo = @{
                                   @"packageName"       :   _packageName,
                                   @"appName"           :   _appName,
                                   @"icon"              :   normal,
                                   @"version"           :   _version,
                                   @"minOSVersion"      :   _minSDKVersion,
                                   @"OSVersion"         :   _sdkVersion,
                                   @"CFBuldleExecutable":   _cfBundleExecutable
                               };
    NSData *objData = [NSJSONSerialization dataWithJSONObject:_appInfo options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:objData encoding:NSUTF8StringEncoding];
    
    NSString *_resutl = [@"<appInfo>" stringByAppendingFormat:@"%@</appInfo>", jsonString];
    [DebugLog showDebugLog:_resutl withDebugLevel:Info];
}

@end
