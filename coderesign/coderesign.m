//
//  coderesign.m
//  coderesign
//
//  Created by MiaoGuangfa on 7/24/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "coderesign.h"
typedef enum {
    Info = 0,
    Debug,
    Error
}DebugLevel;

NSString *const minus_d = @"-d";
NSString *const minus_p = @"-p";
NSString *const minus_e = @"-e";
NSString *const minus_id= @"-id";
NSString *const minus_cer = @"-ci";

NSString *const DISTRIBUTION = @"Distribution";
NSString *const kPayloadDirName = @"Payload";

@interface coderesign ()

@property (nonatomic, strong) NSArray *commands;
@property (nonatomic, strong) NSDictionary *argumentsDictionary;
@property (nonatomic, assign) int argusNumber;
@property (nonatomic, copy) NSString *distribution_resign;
@property (nonatomic, copy) NSString *workingPath;
@property (nonatomic, strong) NSTask *unzipTask;
@property (nonatomic, strong) NSTask *provisioningTask;
@property (nonatomic, strong) NSTask *codesignTask;
@property (nonatomic, copy) NSString *appPath;
@property (nonatomic, strong) NSTask *verifyTask;
@property (nonatomic, strong) NSTask *zipTask;
@property (nonatomic, copy) NSString *verificationResult;
@property (nonatomic, copy) NSString *codesigningResult;
@property (nonatomic,copy) NSString *fileName;

- (void) _showDebugLog:(id)debugMessage withDebugLevel:(DebugLevel)level;


- (BOOL) _doCheckingArgument:(const char *[])argv;
- (BOOL) _doCheckSystemEnvironments;
- (BOOL) _doCheckCertsFromKeychain;
- (BOOL) _doUnzip;
- (void) _doProvisioning;
- (void) _doCodeSigning;
- (void)_doVerifySignature;
@end

static coderesign *shared_coderesign_handler = NULL;

@implementation coderesign

+ (id)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared_coderesign_handler = [[[self class]alloc]init];
        shared_coderesign_handler.commands = @[minus_d, minus_p, minus_e, minus_id, minus_cer];
    });
    
    return shared_coderesign_handler;
}

- (void)resignWithArgv:(const char *[])argv argumentsNumber:(int)argc
{
    [self _showDebugLog:@"########### resign task is running... ###########" withDebugLevel:Info];
    _argusNumber = argc;
    
    if (_argusNumber == 11) {
        if([self _doCheckingArgument:argv]) {
            [self prepare];
        }
        
    }else{
        [self _showDebugLog:@"More or less arguments for codreesign, please confirm and retry!" withDebugLevel:Error];
        exit(0);
    }
}

- (void)prepare
{
    [self _showDebugLog:@"----------------------------- Preparing...-----------------------------" withDebugLevel:Info];
    if ([self _doCheckSystemEnvironments]) {
        if ([self _doCheckCertsFromKeychain]) {
            [self _showDebugLog:@"Prepared completed." withDebugLevel:Info];
            [self _doUnzip];
        }
    }
}



#pragma mark - private methods

- (BOOL)_doUnzip
{
    [self _showDebugLog:@"unzip ipa..." withDebugLevel:Info];
    _workingPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.0x4d4746h.resign"];
    
    NSString *unzippath = [@"unzip ipa to " stringByAppendingString:_workingPath];
    [self _showDebugLog:unzippath withDebugLevel:Info];
    
    NSString *sourcePath = _argumentsDictionary[minus_d];
    
    _unzipTask = [[NSTask alloc] init];
    
    
    [_unzipTask setLaunchPath:@"/usr/bin/unzip"];
    [_unzipTask setArguments:[NSArray arrayWithObjects:@"-q", sourcePath, @"-d", _workingPath, nil]];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkUnzip:) userInfo:nil repeats:TRUE];
    [_unzipTask launch];
    
    

    return true;
}

- (void)checkUnzip:(NSTimer *)timer {
    if ([_unzipTask isRunning] == 0) {
        [timer invalidate];
        _unzipTask = nil;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[_workingPath stringByAppendingPathComponent:kPayloadDirName]]) {
            [self _showDebugLog:@"Unzip completed." withDebugLevel:Info];

            [self _doProvisioning];
            
        } else {
            [self _showDebugLog:@"Unzip Failed" withDebugLevel:Error];
            exit(0);
        }
    }
}


- (void)_doProvisioning
{
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[_workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            _appPath = [[_workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
            if ([[NSFileManager defaultManager] fileExistsAtPath:[_appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
                [self _showDebugLog:@"Found embedded.mobileprovision, deleting." withDebugLevel:Info];

                [[NSFileManager defaultManager] removeItemAtPath:[_appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] error:nil];
            }
            break;
        }
    }

    NSString *targetPath = [_appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
    
    _provisioningTask = [[NSTask alloc] init];
    [_provisioningTask setLaunchPath:@"/bin/cp"];
    [_provisioningTask setArguments:[NSArray arrayWithObjects:_argumentsDictionary[minus_p], targetPath, nil]];
    
    [_provisioningTask launch];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkProvisioning:) userInfo:nil repeats:TRUE];
}

- (void)checkProvisioning:(NSTimer *)timer {
    if ([_provisioningTask isRunning] == 0) {
        [timer invalidate];
        _provisioningTask = nil;
        
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[_workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
        
        for (NSString *file in dirContents) {
            if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
                _appPath = [[_workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
                if ([[NSFileManager defaultManager] fileExistsAtPath:[_appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
                    
                    BOOL identifierOK = FALSE;
                    NSString *identifierInProvisioning = @"";
                    
                    NSString *embeddedProvisioning = [NSString stringWithContentsOfFile:[_appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] encoding:NSASCIIStringEncoding error:nil];
                    NSArray* embeddedProvisioningLines = [embeddedProvisioning componentsSeparatedByCharactersInSet:
                                                          [NSCharacterSet newlineCharacterSet]];
                    
                    for (int i = 0; i <= [embeddedProvisioningLines count]; i++) {
                        if ([[embeddedProvisioningLines objectAtIndex:i] rangeOfString:@"application-identifier"].location != NSNotFound) {
                            
                            NSInteger fromPosition = [[embeddedProvisioningLines objectAtIndex:i+1] rangeOfString:@"<string>"].location + 8;
                            
                            NSInteger toPosition = [[embeddedProvisioningLines objectAtIndex:i+1] rangeOfString:@"</string>"].location;
                            
                            NSRange range;
                            range.location = fromPosition;
                            range.length = toPosition-fromPosition;
                            
                            NSString *fullIdentifier = [[embeddedProvisioningLines objectAtIndex:i+1] substringWithRange:range];
                            
                            NSArray *identifierComponents = [fullIdentifier componentsSeparatedByString:@"."];
                            
                            if ([[identifierComponents lastObject] isEqualTo:@"*"]) {
                                identifierOK = TRUE;
                            }
                            
                            for (int i = 1; i < [identifierComponents count]; i++) {
                                identifierInProvisioning = [identifierInProvisioning stringByAppendingString:[identifierComponents objectAtIndex:i]];
                                if (i < [identifierComponents count]-1) {
                                    identifierInProvisioning = [identifierInProvisioning stringByAppendingString:@"."];
                                }
                            }
                            break;
                        }
                    }
                    
                    NSLog(@"Mobileprovision identifier: %@",identifierInProvisioning);
                    
                    NSString *infoPlist = [NSString stringWithContentsOfFile:[_appPath stringByAppendingPathComponent:@"Info.plist"] encoding:NSASCIIStringEncoding error:nil];
                    if ([infoPlist rangeOfString:identifierInProvisioning].location != NSNotFound) {
                        NSLog(@"Identifiers match");
                        identifierOK = TRUE;
                    }
                    
                    if (identifierOK) {
                        [self _showDebugLog:@"Provisioning completed" withDebugLevel:Info];
                        [self _doCodeSigning];
                    } else {
                        [self _showDebugLog:@"Product identifiers don't match" withDebugLevel:Error];
                        exit(0);
                    }
                } else {
                    NSString * errorInfo = [NSString stringWithFormat:@"No embedded.mobileprovision file in %@", _appPath];
                    [self _showDebugLog:errorInfo withDebugLevel:Error];
                    exit(0);
                }
                break;
            }
        }
    }
}
- (void) _doCodeSigning {
    _appPath = nil;
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[_workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            _appPath = [[_workingPath stringByAppendingPathComponent:kPayloadDirName] stringByAppendingPathComponent:file];
            //NSLog(@"Found %@",_appPath);
            NSString *info = [NSString stringWithFormat:@"Codesigning %@", file];
            [self _showDebugLog:info withDebugLevel:Info];
//            appName = file;
//            [statusLabel setStringValue:[NSString stringWithFormat:@"Codesigning %@",file]];
            break;
        }
    }
    
    if (_appPath) {
        NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"-fs", _distribution_resign, nil];
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
            
            NSString *infoPath = [NSString stringWithFormat:@"%@/Info.plist", _appPath];
            NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath];
            [infoDict removeObjectForKey:@"CFBundleResourceSpecification"];
            [infoDict writeToFile:infoPath atomically:YES];
            [arguments addObject:@"--no-strict"]; // http://stackoverflow.com/a/26204757
        }
        
        
        [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", _argumentsDictionary[minus_e]]];
        
        
        [arguments addObjectsFromArray:[NSArray arrayWithObjects:_appPath, nil]];
        
        _codesignTask = [[NSTask alloc] init];
        [_codesignTask setLaunchPath:@"/usr/bin/codesign"];
        [_codesignTask setArguments:arguments];
        
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCodesigning:) userInfo:nil repeats:TRUE];
        
        
        NSPipe *pipe=[NSPipe pipe];
        [_codesignTask setStandardOutput:pipe];
        [_codesignTask setStandardError:pipe];
        NSFileHandle *handle=[pipe fileHandleForReading];
        
        [_codesignTask launch];
        
        [NSThread detachNewThreadSelector:@selector(watchCodesigning:)
                                 toTarget:self withObject:handle];
    }
}

- (void)watchCodesigning:(NSFileHandle*)streamHandle {
    @autoreleasepool {
        
        _codesigningResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        
    }
}
- (void)checkCodesigning:(NSTimer *)timer {
    if ([_codesignTask isRunning] == 0) {
        [timer invalidate];
        _codesignTask = nil;
        [self _showDebugLog:@"Codesigning completed" withDebugLevel:Info];
        [self _doVerifySignature];
    }
}
- (void)_doVerifySignature {
    if (_appPath) {
        _verifyTask = [[NSTask alloc] init];
        [_verifyTask setLaunchPath:@"/usr/bin/codesign"];
        [_verifyTask setArguments:[NSArray arrayWithObjects:@"-v", _appPath, nil]];
        
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:nil repeats:TRUE];
        
        NSLog(@"Verifying %@",_appPath);
        
        NSPipe *pipe=[NSPipe pipe];
        [_verifyTask setStandardOutput:pipe];
        [_verifyTask setStandardError:pipe];
        NSFileHandle *handle=[pipe fileHandleForReading];
        
        [_verifyTask launch];
        
        [NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
                                 toTarget:self withObject:handle];
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
            [self _showDebugLog:@"Verification completed" withDebugLevel:Info];

            [self doZip];
        } else {
            NSString *error = [[_codesigningResult stringByAppendingString:@"\n\n"] stringByAppendingString:_verificationResult];
            NSString *info = [NSString stringWithFormat:@"Signing failed: %@ ", error ];
            [self _showDebugLog:info withDebugLevel:Error];
            exit(0);
        }
    }
}
- (void)doZip {
    if (_appPath) {
        NSString *sourcePath = _argumentsDictionary[minus_d];
        NSArray *destinationPathComponents = [sourcePath pathComponents];
        NSString *destinationPath = @"";
        
        for (int i = 0; i < ([destinationPathComponents count]-1); i++) {
            destinationPath = [destinationPath stringByAppendingPathComponent:[destinationPathComponents objectAtIndex:i]];
        }
        
        _fileName = [sourcePath lastPathComponent];
        _fileName = [_fileName substringToIndex:([_fileName length] - ([[sourcePath pathExtension] length] + 1))];
        _fileName = [_fileName stringByAppendingString:@"-resigned"];
        _fileName = [_fileName stringByAppendingPathExtension:@"ipa"];
        
        destinationPath = [destinationPath stringByAppendingPathComponent:_fileName];
        
        NSLog(@"Dest: %@",destinationPath);
        
        _zipTask = [[NSTask alloc] init];
        [_zipTask setLaunchPath:@"/usr/bin/zip"];
        [_zipTask setCurrentDirectoryPath:_workingPath];
        [_zipTask setArguments:[NSArray arrayWithObjects:@"-qry", destinationPath, @".", nil]];
        
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkZip:) userInfo:nil repeats:TRUE];
        
        
        NSString *zippingPath = [NSString stringWithFormat:@"Zipping to %@", destinationPath];
        [self _showDebugLog:zippingPath withDebugLevel:Info];
        
        [_zipTask launch];
    }
}

- (void)checkZip:(NSTimer *)timer {
    if ([_zipTask isRunning] == 0) {
        [timer invalidate];
        _zipTask = nil;

        NSString *savedFile = [NSString stringWithFormat:@"Zipping done, file name is %@",_fileName];
        [self _showDebugLog:savedFile withDebugLevel:Info];
        [[NSFileManager defaultManager] removeItemAtPath:_workingPath error:nil];
        
        NSString *result = [[_codesigningResult stringByAppendingString:@"\n\n"] stringByAppendingString:_verificationResult];
        //NSString *coderesign_result = [NSString stringWithFormat:@"coderesign successful";
        [self _showDebugLog:@"coderesign successful" withDebugLevel:Info];
        exit(0);
    }
}

- (BOOL)_doCheckingArgument:(const char *[])argv
{
    [self _showDebugLog:@"----------------------------- Checking passed arguments...-----------------------------" withDebugLevel:Info];
    NSMutableArray *passed_command_flags_ = [NSMutableArray new];
    NSMutableArray *passed_values_ = [NSMutableArray new];
    
    for (int i=0; i<_argusNumber; i++) {
        
        NSLog(@"i=%d i2=%d %s",i,i%2, argv[i]);
        NSString *ns_argv = [NSString stringWithUTF8String:argv[i]];
        
        if (i%2 > 0) {
            [passed_command_flags_ addObject:ns_argv];
            if (![_commands containsObject:ns_argv]) {
                NSString *errorInfo = [NSString stringWithFormat:@"Option '%@' is not support, please confirm and retry!", ns_argv];
                [self _showDebugLog:errorInfo withDebugLevel:Error];
                exit(0);
                //return false;
            }
        }else {
            [passed_values_ addObject:ns_argv];
        }
    }
    
    //remove the coderesign path arguments
    [passed_values_ removeObjectAtIndex:0];
    
    _argumentsDictionary  = [NSDictionary dictionaryWithObjects:passed_values_ forKeys:passed_command_flags_];
    NSLog(@"_argumentsDictionary > %@", _argumentsDictionary);
    
    NSString *ipa               = _argumentsDictionary[minus_d];
    NSString *mobileProvision   = _argumentsDictionary[minus_p];
    NSString *entitlements      = _argumentsDictionary[minus_e];
    NSString *bundleID          = _argumentsDictionary[minus_id];
    NSString *distributionCerName   = _argumentsDictionary[minus_cer];
    
    if (!([[[ipa pathExtension]lowercaseString] isEqualToString:@"ipa"])) {
        [self _showDebugLog:@"ipa file type is not right, please confirm and retry!" withDebugLevel:Error];
        exit(0);
        //return false;
    }
    
    if (!([[[mobileProvision pathExtension]lowercaseString] isEqualToString:@"mobileprovision"])) {
        [self _showDebugLog:@"mobileprovision file type is not right, please confirm and retry!" withDebugLevel:Error];
        exit(0);
        //return false;
    }
    
    if (!([[[entitlements pathExtension]lowercaseString] isEqualToString:@"plist"])) {
        [self _showDebugLog:@"entitlements file type is not right, please confirm and retry!" withDebugLevel:Error];
        exit(0);
        //return false;
    }
    
    if (!bundleID && [bundleID length] == 0) {
        [self _showDebugLog:@"bundle identifler can't be empty, please confirm and retry!" withDebugLevel:Error];
        exit(0);
        //return false;
    }
    
    if (!distributionCerName && [distributionCerName length] == 0) {
        [self _showDebugLog:@"distributionCer name or App ID prefiex can't be empty, please confirm and retry!" withDebugLevel:Error];
        exit(0);
        //return false;
    }
    
    [self _showDebugLog:@"Checking completed with all right arguments." withDebugLevel:Info];
    return true;
}


- (BOOL)_doCheckSystemEnvironments
{
    [self _showDebugLog:@"Checking system environments..." withDebugLevel:Info];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/zip"]) {
        [self _showDebugLog:@"This app cannot run without the zip utility present at /usr/bin/zip" withDebugLevel:Error];
        exit(0);
        //return false;
    }else{
        [self _showDebugLog:@"Checking zip: Installed" withDebugLevel:Info];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/unzip"]) {
        [self _showDebugLog:@"This app cannot run without the zip utility present at /usr/bin/unzip" withDebugLevel:Error];
        exit(0);
        //return false;
    }else{
        [self _showDebugLog:@"Checking unzip: Installed" withDebugLevel:Info];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/codesign"]) {
        [self _showDebugLog:@"This app cannot run without the zip utility present at /usr/bin/codesign" withDebugLevel:Error];
        exit(0);
        //return false;
    }else{
        [self _showDebugLog:@"Checking codesign: Installed" withDebugLevel:Info];
    }
    [self _showDebugLog:@"Checking system completed." withDebugLevel:Info];
    return true;
}

- (void)_showDebugLog:(id)debugMessage withDebugLevel:(DebugLevel)level
{
    if (Error == level) {
        NSLog(@"[Error]: %@", debugMessage);
    }else if (Debug == level) {
        NSLog(@"[Debug]: %@", debugMessage);
    }else if (Info == level) {
        NSLog(@"[Info]: %@", debugMessage);
    }
}


- (BOOL)_doCheckCertsFromKeychain
{
    [self _showDebugLog:@"Checking Signing Certificate IDs from keychain tools..." withDebugLevel:Info];
    
    NSTask *certTask = [[NSTask alloc] init];
    [certTask setLaunchPath:@"/usr/bin/security"];
    [certTask setArguments:[NSArray arrayWithObjects:@"find-identity", @"-v", @"-p", @"codesigning", nil]];
    
    NSPipe *pipe=[NSPipe pipe];
    [certTask setStandardOutput:pipe];
    [certTask setStandardError:pipe];
    NSFileHandle *handle=[pipe fileHandleForReading];
    
    [certTask launch];
    NSString *securityResult = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    
    if (securityResult == nil || securityResult.length < 1) {
        [self _showDebugLog:@"There are no certificates files installed in keychain." withDebugLevel:Error];
        exit(0);
        //return false;
    }
    
    [self _showDebugLog:securityResult withDebugLevel:Debug];
    
    NSArray *rawResult = [securityResult componentsSeparatedByString:@"\""];
    NSMutableArray *cer_results = [NSMutableArray new];
    for (int i = 0; i <= [rawResult count] - 2; i+=2) {
        
       // NSLog(@"i:%d", i+1);
        if (rawResult.count - 1 < i + 1) {
            // Invalid array, don't add an object to that position
        } else {
            // Valid object
            [cer_results addObject:[rawResult objectAtIndex:i+1]];
        }
    }
    //[self _showDebugLog:cer_results withDebugLevel:Info];
    
    NSString *cer_index_distribution   = _argumentsDictionary[minus_cer];
    //if
    
    NSUInteger _count = [cer_results count];
    for (int i=0; i< _count; i++) {
        NSString *cer_name_ = cer_results[i];
        
        NSRange distribution_ns_range = [cer_name_ rangeOfString:DISTRIBUTION];
        NSRange cer_index_range = [cer_name_ rangeOfString:cer_index_distribution];
        
        if (distribution_ns_range.length > 0 && cer_index_range.length > 0) {
            _distribution_resign = cer_name_;
            NSString *_matchedCer = [NSString stringWithFormat:@"Distribution provision <%@> will be used to resign", _distribution_resign];
            [self _showDebugLog:_matchedCer withDebugLevel:Info];
            return true;
        }
    }
    
    if (!_distribution_resign || [_distribution_resign length] == 0) {
        [self _showDebugLog:@"There is no matched certificates file installed in keychain." withDebugLevel:Error];
        exit(0);
        //return false;
    }
    
    return true;
}
@end
