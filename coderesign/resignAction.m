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

@property (nonatomic, strong)NSMutableArray *frameworks;
@property (nonatomic, assign) BOOL hasFrameworks;
@property (nonatomic, assign) BOOL hasExtension;

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
    
    /*
     * Just for swift frameworks
     */
    NSString * frameworksDirPath = nil;
    _hasFrameworks = NO;
    _frameworks = [[NSMutableArray alloc]init];
    NSString *frameworkPath = nil;
    
    
    /*
     * Just for extension app
     */
    _hasExtension = NO;
    NSString *extensionPluginPath = nil;
    
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            [SharedData sharedInstance].appPath = [[[SharedData sharedInstance].workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
            
            /**
             * Resign the swift dylibs if exists these frameworks
             */
            frameworksDirPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:kFrameworksDirName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:frameworksDirPath]) {
                _hasFrameworks = YES;
                NSArray *frameworksContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:frameworksDirPath error:nil];
                for (NSString *frameworkFile in frameworksContents) {
                    NSString *extension = [[frameworkFile pathExtension] lowercaseString];
                    if ([extension isEqualTo:@"framework"] || [extension isEqualTo:@"dylib"]) {
                        frameworkPath = [frameworksDirPath stringByAppendingPathComponent:frameworkFile];
                        [_frameworks addObject:frameworkPath];
                    }
                }
            }
            
            /*
             *
             */
            extensionPluginPath = [[SharedData sharedInstance].appPath stringByAppendingPathComponent:kPlugIns];
            if ([[NSFileManager defaultManager]fileExistsAtPath:extensionPluginPath]) {
                _hasExtension = YES;
                NSArray *_extensionFiles = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:extensionPluginPath error:nil];
                for (NSString *_extensionFile in _extensionFiles) {
                    NSString *_extensionName = [[_extensionFile pathExtension]lowercaseString];
                    if ([_extensionName isEqualToString:@"appex"]) {
                        extensionPluginPath = [extensionPluginPath stringByAppendingPathComponent:_extensionFile];
                        [SharedData sharedInstance].extensionPath = extensionPluginPath;
                    }
                }
                
            }
            
            
            NSString *info = [NSString stringWithFormat:@"Codesigning %@", file];
            [DebugLog showDebugLog:info withDebugLevel:Info];
            break;
        }
    }
    
    if ([SharedData sharedInstance].appPath) {
        
        //resign swift framworks
        if (_hasFrameworks) {
            [self signFile:[_frameworks lastObject]];
            [_frameworks removeLastObject];
        }else if(_hasExtension){
            [self signFile:[SharedData sharedInstance].extensionPath];
        }else {
            //last resign app
            [self signFile:[SharedData sharedInstance].appPath];
        }
    }

}

- (void) signFile:(NSString *)filePath {
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
        
        NSString *infoPath = [NSString stringWithFormat:@"%@/Info.plist", filePath];
        NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath];
        [infoDict removeObjectForKey:@"CFBundleResourceSpecification"];
        [infoDict writeToFile:infoPath atomically:YES];
        [arguments addObject:@"--no-strict"]; // http://stackoverflow.com/a/26204757
    }
    
    if (_hasExtension) {
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", [SharedData sharedInstance].extensionAppEntitlementsPlistPath]];
    }else {
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", [SharedData sharedInstance].entitlementsPlistPath]];
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
        
        if (_frameworks.count > 0) {
            [self signFile:[_frameworks lastObject]];
            [_frameworks removeLastObject];
        }else if (_hasFrameworks){
            _hasFrameworks = NO;
            if (_hasExtension) {
                [self signFile:[SharedData sharedInstance].extensionPath];
                [self _doVerifySignature:kExtensionApp];
                _hasExtension = NO;
            }else {
                [self signFile:[SharedData sharedInstance].appPath];
            }
        }else if (_hasExtension) {
            _hasExtension = NO;
            [self signFile:[SharedData sharedInstance].appPath];
        }else{
            [DebugLog showDebugLog:@"Codesigning completed" withDebugLevel:Info];
            [self _doVerifySignature:kMainApp];
        }
    }
}
- (void)_doVerifySignature:(NSString *)appType {
    if ([appType isEqualToString:kMainApp]) {
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
    }else if ([appType isEqualToString:kExtensionApp]) {
        if ([SharedData sharedInstance].extensionPath) {
            _verifyTask = [[NSTask alloc] init];
            [_verifyTask setLaunchPath:@"/usr/bin/codesign"];
            [_verifyTask setArguments:[NSArray arrayWithObjects:@"-v", [SharedData sharedInstance].extensionPath, nil]];
            
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:nil repeats:TRUE];
            
            NSLog(@"Verifying %@",[SharedData sharedInstance].extensionPath);
            
            NSPipe *pipe=[NSPipe pipe];
            [_verifyTask setStandardOutput:pipe];
            [_verifyTask setStandardError:pipe];
            NSFileHandle *handle=[pipe fileHandleForReading];
            
            [_verifyTask launch];
            
            [NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
                                     toTarget:_instance withObject:handle];
        }
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
