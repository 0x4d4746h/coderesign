//
//  parseAppInfo.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/17/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFParseAppInfo.h"
#import "MGFDecodeicon.h"


static MGFParseAppInfo *_instance = NULL;

@implementation MGFParseAppInfo


- (void)mgf_parseAppInfo
{
    dispatch_queue_t queue = dispatch_queue_create("parse.appinfo.queue", DISPATCH_QUEUE_CONCURRENT);
    
    NSString *_main_infoPlistPath = [self.mgfSharedData.appPath stringByAppendingPathComponent:kInfo_plist];
    
    dispatch_async(queue, ^{
        [self __mgf_startToParse:_main_infoPlistPath withAppType:MainApp];
    });
    
    if (self.mgfSharedData.isSupportWatchKitExtension) {
        NSString *_watchKitExtension_infoPlistPath = [self.mgfSharedData.watchKitExtensionPath stringByAppendingPathComponent:kInfo_plist];
        
        dispatch_async(queue, ^{
            [self __mgf_startToParse:_watchKitExtension_infoPlistPath withAppType:Extension];
        });
    }
    
    if (self.mgfSharedData.isSupportWatchKitApp) {
        NSString *_watchKitApp_infoPlistPath = [self.mgfSharedData.watchKitAppPath stringByAppendingPathComponent:kInfo_plist];
        
        dispatch_async(queue, ^{
            [self __mgf_startToParse:_watchKitApp_infoPlistPath withAppType:WatchApp];
        });
    }
    
    if (self.mgfSharedData.isSupportSharedExtension) {
        NSString *_sharedExtension_infoPlistPath = [self.mgfSharedData.sharedExtensionPath stringByAppendingPathComponent:kInfo_plist];
        
        dispatch_async(queue, ^{
            [self __mgf_startToParse:_sharedExtension_infoPlistPath withAppType:SharedExtension];
        });
    }
    dispatch_barrier_async(queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self mgf_invokeDelegate:self withFinished:TRUE withObject:nil];
        });
    });
   
}

- (void) __mgf_startToParse:(NSString *) infoPlistPath withAppType:(AppType) type {
    @synchronized(self) {
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
        if (type == MainApp && self.mgfSharedData.isResignAndDecode) {
            
            if (_iconName == nil) {
                NSDictionary *bundleIcons = [infoPlist_dictionary objectForKey:@"CFBundleIcons"];
                if(bundleIcons) {
                    NSDictionary *primaryIcon = [bundleIcons objectForKey:@"CFBundlePrimaryIcon"];
                    if(primaryIcon) {
                        NSArray *iconFiles = [primaryIcon objectForKey:@"CFBundleIconFiles"];
                        if (iconFiles) {
                            _iconName = iconFiles[0];
                            
                        }
                    }
                }
                //                CFBundleIcons =     {
                //                    CFBundlePrimaryIcon =         {
                //                        CFBundleIconFiles =             (
                //                                                         AppIcon40x40,
                //                                                         AppIcon60x60
                //                                                         );
                //                        UIPrerenderedIcon = 1;
                //                    };
                //                };
            }
            
            if (_iconName != nil) {
                _iconName = [_iconName stringByAppendingString:@"@2x.png"];
                NSString *icon_file   = [self.mgfSharedData.appPath stringByAppendingPathComponent:_iconName];
                NSData *_icon_data = [[NSFileManager defaultManager]contentsAtPath:icon_file];
                NSString *destinationPath = self.mgfSharedData.commandPath;
                
                NSString *outputPath = [destinationPath stringByAppendingPathComponent:@"Icon-compressed.png"];
                [[NSFileManager defaultManager]createFileAtPath:outputPath contents:_icon_data attributes:nil];
                
                normal_icon = [destinationPath stringByAppendingPathComponent:@"icon.png"];
                [MGFDecodeicon mgf_convertEncryptedImageDataToNormal:outputPath withNewFilePath:normal_icon withPy:[MGFSharedData sharedInstance].crossedArguments[minus_py]];
            }
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
        
        NSString *_result = @"";
        
        if (type == MainApp) {
            _result = [@"<MainAppInfo>" stringByAppendingFormat:@"%@</MainAppInfo>",jsonString];
        }else if (type == Extension) {
            _result = [@"<WatchKitExtensionAppInfo>" stringByAppendingFormat:@"%@</WatchKitExtensionAppInfo>",jsonString];
        }else if (type == WatchApp) {
            _result = [@"<WatchKitAppInfo>" stringByAppendingFormat:@"%@</WatchKitAppInfo>",jsonString];
        }else if (type == SharedExtension) {
            _result = [@"<SharedExtensionAppInfo>" stringByAppendingFormat:@"%@</SharedExtensionAppInfo>",jsonString];
        }
        
        [DebugLog showDebugLog:_result withDebugLevel:Info];
    }
}


- (id)nilToString:(id)object {
    if (object == nil) {
        return @"";
    }
    return object;
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

@end
