//
//  MGFSecurityDecodeMobileProvision.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/18/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFSecurityDecodeMobileProvision.h"

@interface MGFSecurityDecodeMobileProvision ()

@property (nonatomic, strong) NSTask * securityTask;
@property (nonatomic, copy) NSString *stream;

@property (nonatomic, assign) EntitlementsType entitlementsType;

@end

@implementation MGFSecurityDecodeMobileProvision

- (void)mgf_decodeEntitlementsFromMobileProvision:(NSString *)mobileProvisionFilePath withEntitlementsType:(EntitlementsType)entitlementsType
{
    @synchronized(self) {
        _entitlementsType = entitlementsType;
        
        if (mobileProvisionFilePath !=NULL) {
            [self _mgf_decode:mobileProvisionFilePath];
        }else{
            [self mgf_invokeDelegate:self withFinished:FALSE withObject:nil];
        }
    }
}

#pragma private methods
- (void) _mgf_decode:(NSString *)mobileprovisionPath {
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    
    _securityTask = [[NSTask alloc] init];
    [_securityTask setLaunchPath:@"/usr/bin/security"];
    [_securityTask setArguments:[NSArray arrayWithObjects:@"cms", @"-D", @"-i",mobileprovisionPath, nil]];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(__mgf_checkVerificationProcess:) userInfo:nil repeats:TRUE];
    //[runLoop addTimer:_timer forMode:NSDefaultRunLoopMode];
    
    NSPipe *pipe = [NSPipe pipe];
    [_securityTask setStandardOutput:pipe];
    [_securityTask setStandardError:pipe];
    NSFileHandle *handle = [pipe fileHandleForReading];
    
    [_securityTask launch];
    
    [NSThread detachNewThreadSelector:@selector(__mgf_watchVerificationProcess:)
                             toTarget:self withObject:handle];

    [runLoop run];
}

- (void)__mgf_watchVerificationProcess:(NSFileHandle*)streamHandle {
    
    @autoreleasepool {
        _stream = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    }
}
- (void)__mgf_checkVerificationProcess:(NSTimer *)timer {
    if ([_securityTask isRunning] == 0) {
        [timer invalidate];
        _securityTask = nil;
    }
    
    [self __mgf_createEntitlementsFiles];
}

- (void) __mgf_createEntitlementsFiles {
    NSData *plistData = [_stream dataUsingEncoding:NSUTF8StringEncoding];
    NSString *_fileName = [self __mgf_getFilePathWithPrefix:@"decodeMobileProvision"];
    NSString *_path = [self.mgfSharedData.tempPath stringByAppendingPathComponent:_fileName];
    
    [plistData writeToFile: _path atomically:YES];
    
    NSDictionary *dic = [[NSDictionary alloc]initWithContentsOfFile:_path];
    if (dic != nil) {
        if (_entitlementsType == NormalEntitlement) {
            
            //get the origanizational Util
            NSArray *utils = [dic objectForKey:@"TeamIdentifier"];
            if (utils!=nil && utils.count > 0) {
                //cache this value for rename the resigned ipa file
                self.mgfSharedData.origanizationalUnit = utils[0];
            }
        }
        
        NSDictionary *entitlements = [dic objectForKey:@"Entitlements"];
        if (entitlements != nil) {
            //write to entitlements.plist
            
            NSString *_entitlementFileName = [self __mgf_getFilePathWithPrefix:@"entitlements"];

            NSString * entitlementsPlistPath = [self.mgfSharedData.tempPath stringByAppendingPathComponent:_entitlementFileName];
            [entitlements writeToFile:entitlementsPlistPath atomically:YES];
            
            if (_entitlementsType == NormalEntitlement) {
                
                self.mgfSharedData.normalEntitlementsPlistPath = entitlementsPlistPath;
                
            }else if (_entitlementsType == WatchKitExtensionEntitlement) {
                
                self.mgfSharedData.watchKitExtensionEntitlementsPlistPath = entitlementsPlistPath;
                
            }else if (_entitlementsType == WatchKitAppEntitlement){
                
                self.mgfSharedData.watchKitAppEntitlementsPlistPath = entitlementsPlistPath;
                
            }else if (_entitlementsType == SharedExtensionEntitlement) {
                
                self.mgfSharedData.sharedExtensionEntitlementsPlistPath = entitlementsPlistPath;
            }
        }
    }
}

- (NSString *) __mgf_getFilePathWithPrefix:(NSString *)filePrefix {
    
    if (_entitlementsType == NormalEntitlement) {
        filePrefix = [filePrefix stringByAppendingString:@".plist"];
        self.mgfSharedData.normalDecodeMobileProvisionPlistPath = [self.mgfSharedData.tempPath stringByAppendingPathComponent:filePrefix];
    }else if (_entitlementsType == WatchKitExtensionEntitlement) {
        filePrefix = [filePrefix stringByAppendingString:@"_watchkitextension.plist"];
    }else if (_entitlementsType == WatchKitAppEntitlement){
        filePrefix = [filePrefix stringByAppendingString:@"_watchkitapp.plist"];
    }else if (_entitlementsType == SharedExtensionEntitlement) {
        filePrefix = [filePrefix stringByAppendingString:@"_sharedExtension.plist"];
    }
    return filePrefix;
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}
@end
