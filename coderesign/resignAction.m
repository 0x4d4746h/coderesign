//
//  resignAction.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/17/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "resignAction.h"
#import "DebugLog.h"
#import "SharedData.h"
#import "zipUtils.h"

@interface resignAction ()

@property (nonatomic, strong) NSTask *coderesignTask;
@property (nonatomic, strong) NSTask *verifyTask;

@property (nonatomic, copy) NSString *coderesignResult;
@property (nonatomic, copy) NSString *verificationResult;

@end

static resignAction *_instance = NULL;

@implementation resignAction

+ (resignAction *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class]alloc]init];
    });
    
    return _instance;
}

- (void)resign {
    [DebugLog showDebugLog:@"############################################################################ Coderesign..." withDebugLevel:Info];
    [SharedData sharedInstance].appPath = nil;
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[SharedData sharedInstance].workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            [SharedData sharedInstance].appPath = [[[SharedData sharedInstance].workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];

            NSString *info = [NSString stringWithFormat:@"Codesigning %@", file];
            [DebugLog showDebugLog:info withDebugLevel:Info];
            break;
        }
    }
    
    if ([SharedData sharedInstance].appPath) {
        NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"-fs", [SharedData sharedInstance].resignedCerName, nil];
        NSDictionary *systemVersionDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
        NSString * systemVersion = [systemVersionDictionary objectForKey:@"ProductVersion"];
        NSArray * version = [systemVersion componentsSeparatedByString:@"."];
        if ([version[0] intValue]<10 || ([version[0] intValue]==10 && ([version[1] intValue]<9 || ([version[1] intValue]==9 && [version[2] intValue]<5)))) {
            
            /*
             Before OSX 10.9, code signing requires a version 1 signature.
             The resource envelope is necessary.
             To ensure it is added, append the resource flag to the arguments.
             */
            
            NSString *resourceRulesPath = [[NSBundle mainBundle] pathForResource:@"ResourceRules" ofType:@"plist"];
            NSString *resourceRulesArgument = [NSString stringWithFormat:@"--resource-rules=%@",resourceRulesPath];
            [arguments addObject:resourceRulesArgument];
        } else {
            
            /*
             For OSX 10.9 and later, code signing requires a version 2 signature.
             The resource envelope is obsolete.
             To ensure it is ignored, remove the resource key from the Info.plist file.
             */
            
            NSString *infoPath = [NSString stringWithFormat:@"%@/Info.plist", [SharedData sharedInstance].appPath];
            NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath];
            [infoDict removeObjectForKey:@"CFBundleResourceSpecification"];
            [infoDict writeToFile:infoPath atomically:YES];
            [arguments addObject:@"--no-strict"]; // http://stackoverflow.com/a/26204757
        }
        
        
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", [SharedData sharedInstance].crossedArguments[minus_e]]];
        
        
        [arguments addObjectsFromArray:[NSArray arrayWithObjects:[SharedData sharedInstance].appPath, nil]];
        
        _coderesignTask = [[NSTask alloc] init];
        [_coderesignTask setLaunchPath:@"/usr/bin/codesign"];
        [_coderesignTask setArguments:arguments];
        
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:_instance selector:@selector(checkCodesigning:) userInfo:nil repeats:TRUE];
        
        
        NSPipe *pipe=[NSPipe pipe];
        [_coderesignTask setStandardOutput:pipe];
        [_coderesignTask setStandardError:pipe];
        NSFileHandle *handle=[pipe fileHandleForReading];
        
        [_coderesignTask launch];
        
        [NSThread detachNewThreadSelector:@selector(watchCodesigning:)
                                 toTarget:_instance withObject:handle];
    }

}

- (void)watchCodesigning:(NSFileHandle*)streamHandle {
    @autoreleasepool {
        
        _coderesignResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        
    }
}
- (void)checkCodesigning:(NSTimer *)timer {
    if ([_coderesignTask isRunning] == 0) {
        [timer invalidate];
        _coderesignTask = nil;
        [DebugLog showDebugLog:@"Codesigning completed" withDebugLevel:Info];
        [self _doVerifySignature];
    }
}
- (void)_doVerifySignature {
    if ([SharedData sharedInstance].appPath) {
        _verifyTask = [[NSTask alloc] init];
        [_verifyTask setLaunchPath:@"/usr/bin/codesign"];
        [_verifyTask setArguments:[NSArray arrayWithObjects:@"-v", [SharedData sharedInstance].appPath, nil]];
        
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:nil repeats:TRUE];
        
        NSLog(@"Verifying %@",[SharedData sharedInstance].appPath);
        
        NSPipe *pipe=[NSPipe pipe];
        [_verifyTask setStandardOutput:pipe];
        [_verifyTask setStandardError:pipe];
        NSFileHandle *handle=[pipe fileHandleForReading];
        
        [_verifyTask launch];
        
        [NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
                                 toTarget:_instance withObject:handle];
    }
}
- (void)watchVerificationProcess:(NSFileHandle*)streamHandle {
    @autoreleasepool {
        
        _verificationResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        
    }
}
- (void)checkVerificationProcess:(NSTimer *)timer {
    if ([_verifyTask isRunning] == 0) {
        [timer invalidate];
        _verifyTask = nil;
        if ([_verificationResult length] == 0) {
            [DebugLog showDebugLog:Pass];
            
            [[zipUtils sharedInstance]doZip];
        } else {
            NSString *error = [[_coderesignResult stringByAppendingString:@"\n\n"] stringByAppendingString:_verificationResult];
            NSString *info = [NSString stringWithFormat:@"Signing failed: %@ ", error ];
            [DebugLog showDebugLog:info withDebugLevel:Error];
            exit(0);
        }
    }
}

@end
