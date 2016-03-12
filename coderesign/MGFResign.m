//
//  resignAction.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/17/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFResign.h"
#import "MGFZipUtils.h"


@interface MGFResign ()

@property (nonatomic, strong) NSTask *coderesignTask;
@property (nonatomic, strong) NSTask *verifyTask;

@property (nonatomic, copy) NSString *coderesignResult;
@property (nonatomic, copy) NSString *verificationResult;
@property (nonatomic, assign) AppType currentType;

@end


@implementation MGFResign

- (void)mgf_resign {
    
    [DebugLog showDebugLog:@"############################################################################ Coderesign..." withDebugLevel:Debug];
    
    dispatch_queue_t queue = dispatch_queue_create("resign.queue", DISPATCH_QUEUE_SERIAL);
    
    /**
     * 由内而外重签
     */
    if (self.mgfSharedData.isSupportWatchKitApp) {
        dispatch_async(queue, ^{
            [self __mgf_signFile:self.mgfSharedData.watchKitAppPath withAppType:WatchApp];
        });
    }
    
    if (self.mgfSharedData.isSupportWatchKitExtension) {
        dispatch_async(queue, ^{
            [self __mgf_signFile:self.mgfSharedData.watchKitExtensionPath withAppType:Extension];
        });
    }
    
    if (self.mgfSharedData.isSupportSharedExtension) {
        dispatch_async(queue, ^{
            [self __mgf_signFile:self.mgfSharedData.sharedExtensionPath withAppType:SharedExtension];
        });
    }
    
    if (self.mgfSharedData.isSupportLibrary) {
        for (NSString *_libraryPath in self.mgfSharedData.libraryArray) {
            dispatch_async(queue, ^{
                [self __mgf_signFile:_libraryPath withAppType:Swift];
            });
        }
    }
    dispatch_async(queue, ^{
        [self __mgf_signFile:self.mgfSharedData.appPath withAppType:MainApp];
    });
    
    dispatch_barrier_async(queue, ^{
        [[MGFSharedData sharedInstance].libraryArray removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self mgf_invokeDelegate:self withFinished:TRUE withObject:nil];
        });
    });
}

#pragma private methods
- (void)__mgf_signFile:(NSString *)filePath withAppType:(AppType)type
{
    _currentType = type;
    NSString *_resignFilePath = [@"Start to sign file: " stringByAppendingFormat:@"%@, AppType: %d", filePath, type];
    [DebugLog showDebugLog:_resignFilePath withDebugLevel:Debug];
    
    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"-fs", self.mgfSharedData.resignedCerName, nil];
    
    if (type == MainApp) {
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", self.mgfSharedData.normalEntitlementsPlistPath]];
    }else if (type == Swift){
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", self.mgfSharedData.normalEntitlementsPlistPath]];
    }else if(type == Extension){
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", self.mgfSharedData.watchKitExtensionEntitlementsPlistPath]];
    }else if (type == WatchApp) {
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", self.mgfSharedData.watchKitAppEntitlementsPlistPath]];
    }else if (type == SharedExtension) {
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", self.mgfSharedData.sharedExtensionEntitlementsPlistPath]];
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
        if (type !=Swift) {
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
    }
    
    [arguments addObjectsFromArray:[NSArray arrayWithObjects:filePath, nil]];
    
    _coderesignTask = [[NSTask alloc] init];
    [_coderesignTask setLaunchPath:@"/usr/bin/codesign"];
    [_coderesignTask setArguments:arguments];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCodesigning:) userInfo:nil repeats:TRUE];
    
    
    NSPipe *pipe=[NSPipe pipe];
    [_coderesignTask setStandardOutput:pipe];
    [_coderesignTask setStandardError:pipe];
    NSFileHandle *handle=[pipe fileHandleForReading];
    
    [_coderesignTask launch];
    
    [NSThread detachNewThreadSelector:@selector(watchCodesigning:) toTarget:self withObject:handle];
    
    [[NSRunLoop currentRunLoop]run];
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
        //[DebugLog showDebugLog:@"Codesigning completed" withDebugLevel:Debug];
        if (_currentType !=Swift) {
            [self _doVerifySignature];
        }
    }
}
- (void)_doVerifySignature {
    _verifyTask = [[NSTask alloc] init];
    [_verifyTask setLaunchPath:@"/usr/bin/codesign"];
    
    if (_currentType == MainApp) {
        [_verifyTask setArguments:[NSArray arrayWithObjects:@"-v", self.mgfSharedData.appPath, nil]];
        NSLog(@"Verifying %@, AppType: %d",self.mgfSharedData.appPath, _currentType);
    }else if (_currentType == Extension) {
        [_verifyTask setArguments:[NSArray arrayWithObjects:@"-v", self.mgfSharedData.watchKitExtensionPath, nil]];
        NSLog(@"Verifying %@, AppType: %d",self.mgfSharedData.watchKitExtensionPath, _currentType);
    }else if (_currentType == WatchApp) {
        [_verifyTask setArguments:[NSArray arrayWithObjects:@"-v", self.mgfSharedData.watchKitAppPath, nil]];
        NSLog(@"Verifying %@, AppType: %d",self.mgfSharedData.watchKitAppPath, _currentType);
    }else if (_currentType == SharedExtension) {
        [_verifyTask setArguments:[NSArray arrayWithObjects:@"-v", self.mgfSharedData.sharedExtensionPath, nil]];
        NSLog(@"Verifying %@, AppType: %d",self.mgfSharedData.sharedExtensionPath, _currentType);
    }
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:nil repeats:TRUE];
    
    NSPipe *pipe=[NSPipe pipe];
    [_verifyTask setStandardOutput:pipe];
    [_verifyTask setStandardError:pipe];
    NSFileHandle *handle=[pipe fileHandleForReading];
    
    [_verifyTask launch];
    
    [NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
                             toTarget:self withObject:handle];
    
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
            [DebugLog showDebugLog:@"Verifying resigned package success. [Pass]" withDebugLevel:Debug];
            
        } else {
            NSString *error = [[_coderesignResult stringByAppendingString:@"\n\n"] stringByAppendingString:_verificationResult];
            NSString *info = [NSString stringWithFormat:@"Signing failed: %@ ", error ];
            [DebugLog showDebugLog:info withDebugLevel:Error];
        }
    }
}

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
}

@end
