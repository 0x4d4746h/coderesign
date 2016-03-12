//
//  checkAppCPUConstruction.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/17/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFCheckCPUConstruction.h"

@interface MGFCheckCPUConstruction ()

@property (nonatomic, strong) NSTask *cpuCheckerTask;
@property (nonatomic, copy) NSString *verificationResult;

@end


@implementation MGFCheckCPUConstruction

- (void)mgf_checkCPUContruction
{
    [DebugLog showDebugLog:@"checking CPU construction for this app" withDebugLevel:Debug];

    _cpuCheckerTask = [[NSTask alloc] init];
    [_cpuCheckerTask setLaunchPath:@"/usr/bin/codesign"];
    [_cpuCheckerTask setArguments:[NSArray arrayWithObjects:@"-vv", @"-d", self.mgfSharedData.appPath, nil]];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:nil repeats:TRUE];
    
    NSPipe *pipe=[NSPipe pipe];
    [_cpuCheckerTask setStandardOutput:pipe];
    [_cpuCheckerTask setStandardError:pipe];
    NSFileHandle *handle=[pipe fileHandleForReading];
    
    [_cpuCheckerTask launch];
    
    [NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
                             toTarget:self withObject:handle];
}

- (void)watchVerificationProcess:(NSFileHandle*)streamHandle {
    @autoreleasepool {
        _verificationResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    }
}
- (void)checkVerificationProcess:(NSTimer *)timer {
    if ([_cpuCheckerTask isRunning] == 0) {
        [timer invalidate];
        _cpuCheckerTask = nil;
        NSMutableArray *_cpuType = [NSMutableArray new];
        if ([_verificationResult containsString:@"armv7"]) {
            [_cpuType addObject:@"Armv7"];
        }
        if ([_verificationResult containsString:@"arm64"]){
            [_cpuType addObject:@"Arm64"];
        }
        if ([_verificationResult containsString:@"armv7s"]){
            
            [_cpuType addObject:@"Armv7s"];
        }
        NSString *_result = [@"Support CPU type: <CPU>" stringByAppendingFormat:@"%@</CPU>", _cpuType];
        [DebugLog showDebugLog:_result withDebugLevel:Info];
        [self mgf_invokeDelegate:self withFinished:TRUE withObject:nil];
    }
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}
@end
