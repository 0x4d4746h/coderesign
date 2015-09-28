//
//  securityEncodeDecodeMobileProvision.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/18/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "securityEncodeDecodeMobileProvision.h"
#import "SharedData.h"
#import  "DebugLog.h"


@interface securityEncodeDecodeMobileProvision ()

@property (nonatomic, strong) NSTask * securityTask;
@property (nonatomic, copy) NSString *stream;
@property (nonatomic, strong) NSDictionary *entitlements;
@property (nonatomic, assign) BOOL isDumpExtension;

@end

static securityEncodeDecodeMobileProvision *_instance = NULL;
@implementation securityEncodeDecodeMobileProvision

+ (securityEncodeDecodeMobileProvision *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class]alloc]init];
    });
    return _instance;
}

- (void)dumpEntitlements
{

    NSString *mobileprovisionPath = [SharedData sharedInstance].crossedArguments[minus_p];
   
    if (mobileprovisionPath !=NULL) {
        [self _dump:mobileprovisionPath];
    }
    
}

- (void) _dump:(NSString *)mobileprovisionPath {
    _securityTask = [[NSTask alloc] init];
    [_securityTask setLaunchPath:@"/usr/bin/security"];
    [_securityTask setArguments:[NSArray arrayWithObjects:@"cms", @"-D", @"-i",mobileprovisionPath, nil]];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:nil repeats:TRUE];
    
    NSPipe *pipe=[NSPipe pipe];
    [_securityTask setStandardOutput:pipe];
    [_securityTask setStandardError:pipe];
    NSFileHandle *handle=[pipe fileHandleForReading];
    
    [_securityTask launch];
    
    [NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
                             toTarget:self withObject:handle];
}

- (void)watchVerificationProcess:(NSFileHandle*)streamHandle {
    @autoreleasepool {
        _stream = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    }
}
- (void)checkVerificationProcess:(NSTimer *)timer {
    if ([_securityTask isRunning] == 0) {
        [timer invalidate];
        _securityTask = nil;
    }
    
    [self _createEntitlementsFiles];
    
    if (_isDumpExtension) {
        _isDumpExtension = NO;
        return;
    }
    
     NSString *extensionMobileprovisionPath = [SharedData sharedInstance].crossedArguments[minus_ex];
    if (extensionMobileprovisionPath != NULL) {
        _isDumpExtension = YES;
        [self _dump:extensionMobileprovisionPath];
    }
}

- (void) _createEntitlementsFiles {
    NSData *plistData = [_stream dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *_fileName = @"decodeMobileProvision";
    if (_isDumpExtension) {
        _fileName = [_fileName stringByAppendingString:@"_extension.plist"];
    }else{
        _fileName = [_fileName stringByAppendingString:@".plist"];
    }
    NSString *_path = [[SharedData sharedInstance].tempPath stringByAppendingPathComponent:_fileName];
    
    [plistData writeToFile: _path atomically:YES];
    
    NSDictionary *dic = [[NSDictionary alloc]initWithContentsOfFile:_path];
    if (dic != nil) {
        _entitlements = [dic objectForKey:@"Entitlements"];
        if (_entitlements != nil) {
            //write to entitlements.plist
            
            NSString *_entitlementFileName = @"entitlements";
            if (_isDumpExtension) {
                _entitlementFileName = [_entitlementFileName stringByAppendingString:@"_extension.plist"];
            }else {
                _entitlementFileName = [_entitlementFileName stringByAppendingString:@".plist"];
            }
            
            NSString * entitlementsPlistPath = [[SharedData sharedInstance].tempPath stringByAppendingPathComponent:_entitlementFileName];
            [_entitlements writeToFile:entitlementsPlistPath atomically:YES];
            
            
            if (_isDumpExtension) {
                [SharedData sharedInstance].extensionAppEntitlementsPlistPath = entitlementsPlistPath;
                [SharedData sharedInstance].extensionAppGroups = [_entitlements objectForKey:@"com.apple.security.application-groups"];
            }else {
                [SharedData sharedInstance].entitlementsPlistPath = entitlementsPlistPath;
                [SharedData sharedInstance].appGroups = [_entitlements objectForKey:@"com.apple.security.application-groups"];
            }
            
        }
    }
}

@end
