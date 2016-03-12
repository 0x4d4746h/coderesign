//
//  parsePlayload.m
//  coderesign
//
//  Created by MiaoGuangfa on 10/10/15.
//  Copyright © 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFParsePlayload.h"
#import "MGFSecurityDecodeMobileProvision.h"

@interface MGFParsePlayload ()

@property (nonatomic, copy) NSString * mgfPlayloadPath;

@end

@implementation MGFParsePlayload

- (instancetype)init {
    self = [super init];
    if (self) {
        _mgfPlayloadPath = [self.mgfSharedData.workingPath stringByAppendingPathComponent:kPayloadDirName];
    }
    return self;
}

- (void)mgf_parsePlayload
{
    NSArray *playloadFileContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_mgfPlayloadPath error:nil];
    for (NSString *file in playloadFileContents) {
        
        //just run one time.
        if ([[[file pathExtension] lowercaseString] isEqualToString:kApp]) {
            self.mgfSharedData.appPath = [_mgfPlayloadPath stringByAppendingPathComponent:file];
            
            /**
             * check frameworks and dylibs in app path, save them to libraryArray.
             */
            
            NSArray *appContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.mgfSharedData.appPath error:nil];
            for(NSString *_item in appContents) {
                if ([_item.pathExtension.lowercaseString isEqualToString:kDylib]) {
                    [self.mgfSharedData.libraryArray addObject:[self.mgfSharedData.appPath stringByAppendingPathComponent:_item]];
                    self.mgfSharedData.isSupportLibrary = TRUE;
                }
            }
            
            /**
             * Check if Frameworks exists or not.
             */
            NSString *frameworksDirPath = [self.mgfSharedData.appPath stringByAppendingPathComponent:kFrameworksDirName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:frameworksDirPath]) {
                
                NSArray *frameworksContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:frameworksDirPath error:nil];
                for (NSString *frameworkFile in frameworksContents) {
                    NSString *extension = [[frameworkFile pathExtension] lowercaseString];
                    if ([extension isEqualTo:kFramework] || [extension isEqualTo:kDylib]) {
                        [self.mgfSharedData.libraryArray addObject:[frameworksDirPath stringByAppendingPathComponent:frameworkFile]];
                    }
                }
                
                // ../Frameworks/
                self.mgfSharedData.isSupportLibrary = TRUE;
            }
            
            
            /**
             * Check if support App Group
             */
            NSString *appMobileProvision = [self.mgfSharedData.appPath stringByAppendingPathComponent:kEmbedded_MobileProvision];
            if ([[NSFileManager defaultManager] fileExistsAtPath:appMobileProvision]) {
                NSString *embeddedProvisioning = [NSString stringWithContentsOfFile:appMobileProvision encoding:NSASCIIStringEncoding error:nil];
                NSArray* embeddedProvisioningLines = [embeddedProvisioning componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                
                for (int i = 0; i < [embeddedProvisioningLines count]; i++) {
                    if ([[embeddedProvisioningLines objectAtIndex:i] rangeOfString:kApple_security_group].location != NSNotFound) {
                        
                        // Find it
                        self.mgfSharedData.isSupportAppGroup = TRUE;
                    }
                }
            }
            
            
            /**
             * Check if PlugIns exists or not.
             */
            //PlugIns
            NSString *extensionPluginPath = [self.mgfSharedData.appPath stringByAppendingPathComponent:kPlugIns];

            if ([[NSFileManager defaultManager]fileExistsAtPath:extensionPluginPath]) {
                [MGFSharedData sharedInstance].plugInsPath = extensionPluginPath;
                
                NSArray *_extensionFiles = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:extensionPluginPath error:nil];
                
                //loop all appex, and find the watch kit extension - watch kit app, and shared extension without any app include
                for (NSString *_extensionFile in _extensionFiles) {
                    if ([_extensionFile.pathExtension.lowercaseString isEqualToString:kAppex]) {
                        
                        NSString *_appexPath    = [extensionPluginPath stringByAppendingPathComponent:_extensionFile];
                        NSArray *_appexContents = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:_appexPath error:nil];
                        NSUInteger _end_index   = (_appexContents.count -1);
                        
                        [_appexContents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            NSString *_appexContent = (NSString *)obj;
                            if ([_appexContent.pathExtension.lowercaseString isEqualToString:kApp]) {
                                self.mgfSharedData.watchKitExtensionPath        = _appexPath;
                                self.mgfSharedData.watchKitAppPath              = [_appexPath stringByAppendingPathComponent:_appexContent];
                                
                                self.mgfSharedData.isSupportWatchKitApp         = TRUE;
                                self.mgfSharedData.isSupportWatchKitExtension   = TRUE;
                                self.mgfSharedData.watchKitExtensionEntitlementsPath = [_appexPath stringByAppendingPathComponent:kEntitlements];
                                *stop = TRUE;
                            }else if (idx == _end_index) {
                                self.mgfSharedData.sharedExtensionPath          = _appexPath;
                                self.mgfSharedData.isSupportSharedExtension     = TRUE;
                                self.mgfSharedData.sharedExtensionEntitlementsPath = [_appexPath stringByAppendingPathComponent:kEntitlements];
                            }
                        }];
                    }
                }
            }
            
            //end to parse
            [self mgf_invokeDelegate:self withFinished:TRUE withObject:nil];
        }
    }
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

@end
