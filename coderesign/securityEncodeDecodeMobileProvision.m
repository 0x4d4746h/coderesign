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
    _securityTask = [[NSTask alloc] init];
    [_securityTask setLaunchPath:@"/usr/bin/security"];
    [_securityTask setArguments:[NSArray arrayWithObjects:@"cms", @"-D", @"-i",[SharedData sharedInstance].crossedArguments[minus_p], nil]];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:nil repeats:TRUE];
    
    NSPipe *pipe=[NSPipe pipe];
    [_securityTask setStandardOutput:pipe];
    [_securityTask setStandardError:pipe];
    NSFileHandle *handle=[pipe fileHandleForReading];
    
    [_securityTask launch];
    
    [NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
                             toTarget:self withObject:handle];
}- (void)watchVerificationProcess:(NSFileHandle*)streamHandle {
    @autoreleasepool {
        _stream = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    }
}
- (void)checkVerificationProcess:(NSTimer *)timer {
    if ([_securityTask isRunning] == 0) {
        [timer invalidate];
        _securityTask = nil;
    }
    NSData *plistData = [_stream dataUsingEncoding:NSUTF8StringEncoding];
    NSString *_path = [[SharedData sharedInstance].tempPath stringByAppendingPathComponent:@"decodeMobileProvision.plist"];
 
    [plistData writeToFile: _path atomically:YES];
    
    NSDictionary *dic = [[NSDictionary alloc]initWithContentsOfFile:_path];
    if (dic != nil) {
        _entitlements = [dic objectForKey:@"Entitlements"];
        if (_entitlements != nil) {
            //write to entitlements.plist
            NSString * entitlementsPlistPath = [[SharedData sharedInstance].tempPath stringByAppendingPathComponent:@"entitlements.plist"];
            [_entitlements writeToFile:entitlementsPlistPath atomically:YES];
            [SharedData sharedInstance].entitlementsPlistPath = entitlementsPlistPath;
        }
    }
}
- (void)encode
{
}
- (void)decode
{
    
}
@end
