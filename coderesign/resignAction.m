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

typedef void(^SignFinishedBlock)(BOOL isFinished);

@interface resignAction ()

@property (nonatomic, strong) NSTask *coderesignTask;
@property (nonatomic, strong) NSTask *verifyTask;

@property (nonatomic, copy) NSString *coderesignResult;
@property (nonatomic, copy) NSString *verificationResult;

//@property (nonatomic, strong)NSMutableArray *frameworks;
//@property (nonatomic, assign) BOOL hasFrameworks;
//@property (nonatomic, assign) BOOL hasExtension;

@property (nonatomic, copy) SignFinishedBlock signFinishedBlock;
@property (nonatomic, assign) AppType currentAppType;

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
    
    
    if ([SharedData sharedInstance].isSupportWatchKitApp) {
        _currentAppType = WatchApp;
        
        [self signFile:[SharedData sharedInstance].watchKitAppPath withAppType:WatchApp withFinishedBlock:^(BOOL isFinished) {
            if (isFinished) {
                if ([SharedData sharedInstance].isSupportWatchKitExtension) {
                    _currentAppType = WatchApp;
                    
                    [self signFile:[SharedData sharedInstance].watchKitExtensionPath withAppType:Extension withFinishedBlock:^(BOOL isFinished) {
                        if (isFinished) {
                            /**
                             * Sign swift frameworks if exists
                             */
                            if ([SharedData sharedInstance].isSupportSwift) {
                                _currentAppType = Swift;
                                [self signSwiftFrameworksSyncWithBlock:^(BOOL isFinished) {
                                    if (isFinished) {
                                        [self signFile:[SharedData sharedInstance].appPath withAppType:MainApp withFinishedBlock:^(BOOL isFinished) {
                                            [self _doZip];
                                        }];
                                    }
                                }];
                            }else{
                                [self signFile:[SharedData sharedInstance].appPath withAppType:MainApp withFinishedBlock:^(BOOL isFinished) {
                                    [self _doZip];
                                }];
                            }
                        }
                    }];
                }
            }
        }];
        
    }else{
        /**
         * Sign swift frameworks if exists
         */
        if ([SharedData sharedInstance].isSupportSwift) {
            _currentAppType = Swift;
            [self signSwiftFrameworksSyncWithBlock:^(BOOL isFinished) {
                if (isFinished) {
                    [self signFile:[SharedData sharedInstance].appPath withAppType:MainApp withFinishedBlock:^(BOOL isFinished) {
                        [self _doZip];
                    }];
                }
            }];
        }else{
            [self signFile:[SharedData sharedInstance].appPath withAppType:MainApp withFinishedBlock:^(BOOL isFinished) {
                [self _doZip];
            }];
        }
    }
    
//    dispatch_sync(cocurrentQueue, ^{
//        [self signFile:[SharedData sharedInstance].appPath withAppType:MainApp withFinishedBlock:^(BOOL isFinished) {
//            [self _doZip];
//        }];
//    });
    
        
//    }
    
    
    /**
     * Sign watch kit app if support.
     */
//    if ([SharedData sharedInstance].isSupportWatchKitApp) {
//        _currentAppType = WatchApp;
//        
//        [self signFile:[SharedData sharedInstance].watchKitAppPath withAppType:WatchApp withFinishedBlock:^(BOOL isFinished) {
//            if (isFinished) {
//                dispatch_group_leave(resignGroup);
//            }
//        }];
//    }else {
//        dispatch_group_leave(resignGroup);
//    }
//    
//    dispatch_group_enter(resignGroup);
//    //sign watch kit extension
//    if ([SharedData sharedInstance].isSupportWatchKitExtension) {
//        _currentAppType = Extension;
//        
//        [self signFile:[SharedData sharedInstance].watchKitExtensionPath withAppType:Extension withFinishedBlock:^(BOOL isFinished) {
//            if (isFinished) {
//                dispatch_group_leave(resignGroup);
//            }
//        }];
//    }else{
//        dispatch_group_leave(resignGroup);
//    }
//    
//    dispatch_group_enter(resignGroup);
//    /**
//     * Sign swift frameworks if exists
//     */
//    if ([SharedData sharedInstance].isSupportSwift) {
//        _currentAppType = Swift;
//        [self signSwiftFrameworksSyncWithBlock:^(BOOL isFinished) {
//            dispatch_group_leave(resignGroup);
//        }];
//    }else{
//        dispatch_group_leave(resignGroup);
//    }
//    
//    dispatch_group_notify(resignGroup, dispatch_get_main_queue(), ^{
//       [self signFile:[SharedData sharedInstance].appPath withAppType:MainApp withFinishedBlock:^(BOOL isFinished) {
//           [self _doZip];
//       }];
//    });
}


- (void) signSwiftFrameworksSyncWithBlock:(void(^)(BOOL isFinished)) finishedBlock {
    dispatch_group_t swiftSignGroup = dispatch_group_create();
    NSUInteger _count = [SharedData sharedInstance].swiftFrameworks.count;
    
    for (NSUInteger index=0; index<_count; index++) {
        dispatch_group_enter(swiftSignGroup);
        
        NSString *_swift_frame_file_path = [[SharedData sharedInstance].swiftFrameworks objectAtIndex:index];
        
        [self signFile:_swift_frame_file_path withAppType:Swift withFinishedBlock:^(BOOL isFinished) {
            if (isFinished) {
                dispatch_group_leave(swiftSignGroup);
            }
        }];
    }
    
    dispatch_group_notify(swiftSignGroup, dispatch_get_main_queue(), ^{
        [[SharedData sharedInstance].swiftFrameworks removeAllObjects];
        [SharedData sharedInstance].swiftFrameworks = nil;
        finishedBlock (TRUE);
    });
}


- (void) signFile:(NSString *)filePath withAppType:(AppType)type withFinishedBlock:(SignFinishedBlock) finishedBlock
{
    
    _signFinishedBlock = finishedBlock;
    NSString *_resignFilePath = [@"Start to sign file: " stringByAppendingFormat:@"%@", filePath];
    [DebugLog showDebugLog:_resignFilePath withDebugLevel:Info];
    
    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"-fs", [SharedData sharedInstance].resignedCerName, nil];
    
    if (type == MainApp) {
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", [SharedData sharedInstance].normalEntitlementsPlistPath]];
    }else if (type == Swift){
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", [SharedData sharedInstance].normalEntitlementsPlistPath]];
    }else if(type == Extension){
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", [SharedData sharedInstance].watchKitExtensionEntitlementsPlistPath]];
    }else if (type == WatchApp) {
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", [SharedData sharedInstance].watchKitAppEntitlementsPlistPath]];
    }
    
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
        
        NSString *infoPath = [NSString stringWithFormat:@"%@/Info.plist", filePath];
        NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath];
        [infoDict removeObjectForKey:@"CFBundleResourceSpecification"];
        [infoDict writeToFile:infoPath atomically:YES];
        [arguments addObject:@"--no-strict"]; // http://stackoverflow.com/a/26204757
    }
    
    [arguments addObjectsFromArray:[NSArray arrayWithObjects:filePath, nil]];
    
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
    if (_currentAppType == Swift) {
        _signFinishedBlock (TRUE);
        return;
    }
    
    _verifyTask = [[NSTask alloc] init];
    [_verifyTask setLaunchPath:@"/usr/bin/codesign"];
    
    if (_currentAppType == MainApp) {
        [_verifyTask setArguments:[NSArray arrayWithObjects:@"-v", [SharedData sharedInstance].appPath, nil]];
        NSLog(@"Verifying %@",[SharedData sharedInstance].appPath);
    }else if (_currentAppType == Extension) {
        [_verifyTask setArguments:[NSArray arrayWithObjects:@"-v", [SharedData sharedInstance].watchKitExtensionPath, nil]];
        NSLog(@"Verifying %@",[SharedData sharedInstance].watchKitExtensionPath);
    }else if (_currentAppType == WatchApp) {
        [_verifyTask setArguments:[NSArray arrayWithObjects:@"-v", [SharedData sharedInstance].watchKitAppPath, nil]];
        NSLog(@"Verifying %@",[SharedData sharedInstance].watchKitAppPath);
    }
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:nil repeats:TRUE];
    
    NSPipe *pipe=[NSPipe pipe];
    [_verifyTask setStandardOutput:pipe];
    [_verifyTask setStandardError:pipe];
    NSFileHandle *handle=[pipe fileHandleForReading];
    
    [_verifyTask launch];
    
    [NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
                             toTarget:_instance withObject:handle];
    
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
            [DebugLog showDebugLog:@"Verifying resigned package success. [Pass]" withDebugLevel:Info];
            
            _signFinishedBlock (TRUE);
            
        } else {
            NSString *error = [[_coderesignResult stringByAppendingString:@"\n\n"] stringByAppendingString:_verificationResult];
            NSString *info = [NSString stringWithFormat:@"Signing failed: %@ ", error ];
            [DebugLog showDebugLog:info withDebugLevel:Error];
            _signFinishedBlock (FALSE);
            exit(0);
        }
    }
}

- (void) _doZip {
    [DebugLog showDebugLog:Pass];
    [[zipUtils sharedInstance]doZipWithFinishedBlock:^(BOOL isFinished) {
        if (isFinished) {
            [[NSFileManager defaultManager] removeItemAtPath:[SharedData sharedInstance].workingPath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[SharedData sharedInstance].tempPath error:nil];
            [DebugLog showDebugLog:@"coderesign successful" withDebugLevel:Info];
            [DebugLog showDebugLog:AllDone];
            exit(0);
        }
    }];
}

@end
