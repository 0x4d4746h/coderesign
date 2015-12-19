//
//  securityEncodeDecodeMobileProvision.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/18/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "securityEncodeDecodeMobileProvision.h"
#import "SharedData.h"
#import "DebugLog.h"


@interface securityEncodeDecodeMobileProvision ()

@property (nonatomic, strong) NSTask * securityTask;
@property (nonatomic, copy) NSString *stream;

@property (nonatomic, assign) EntitlementsType entitlementsType;
@property (nonatomic, copy) finished finishedBlock;
@property (nonatomic, assign) BOOL isCheckingInHouseType;

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

- (void)dumpEntitlementsFromMobileProvision:(NSString *)mobileProvisionFilePath withEntitlementsType:(EntitlementsType)entitlementsType withBlock:(finished)finishedBlock
{
    _entitlementsType = entitlementsType;
    _finishedBlock = finishedBlock;
    
    if (mobileProvisionFilePath !=NULL) {
        [self _dump:mobileProvisionFilePath];
    }else{
        _finishedBlock (FALSE, entitlementsType);
    }
}
- (void)checkIfInHouseType:(NSString *)mobileProvisionFilePath withBlock:(finished)finishedBlock
{
    _finishedBlock = finishedBlock;
    if (mobileProvisionFilePath != NULL) {
        _isCheckingInHouseType = YES;
        [self _dump:mobileProvisionFilePath];
    }else{
        _finishedBlock(FALSE, Normal);
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
}

- (void) _createEntitlementsFiles {
    NSData *plistData = [_stream dataUsingEncoding:NSUTF8StringEncoding];
    NSString *_fileName = [self _getFilePathWithPrefix:@"decodeMobileProvision"];
    NSString *_path = [[SharedData sharedInstance].tempPath stringByAppendingPathComponent:_fileName];
    
    [plistData writeToFile: _path atomically:YES];
    
    NSDictionary *dic = [[NSDictionary alloc]initWithContentsOfFile:_path];
    if (dic != nil) {
        if (_entitlementsType == Normal) {
            
            //get the origanizational Util
            NSArray *utils = [dic objectForKey:@"TeamIdentifier"];
            if (utils!=nil && utils.count > 0) {
                //cache this value for rename the resigned ipa file
                [SharedData sharedInstance].origanizationalUnit = utils[0];
            }
        }
        
        if (_isCheckingInHouseType) {
            
            //continue to check inhouse type
            BOOL _tag = (BOOL)[dic objectForKey:@"ProvisionsAllDevices"];
            if (_tag) {
                [SharedData sharedInstance].isInHouseType = TRUE;
                [DebugLog showDebugLog:@"IPA is In-House type, NOT need to resign" withDebugLevel:Debug];
                
                NSDictionary *_inhouse_type = @{@"ProvisionsAllDevices"       :   @(_tag)};
                NSData *objData = [NSJSONSerialization dataWithJSONObject:_inhouse_type options:NSJSONWritingPrettyPrinted error:nil];
                NSString *jsonString = [[NSString alloc]initWithData:objData encoding:NSUTF8StringEncoding];
                
                NSString *_resutl = [@"<InHouse>" stringByAppendingFormat:@"%@</InHouse>",jsonString];
                [DebugLog showDebugLog:_resutl withDebugLevel:Info];
            }
            _isCheckingInHouseType = FALSE;
            _finishedBlock (TRUE, Normal);
        }else{
            NSDictionary *entitlements = [dic objectForKey:@"Entitlements"];
            if (entitlements != nil) {
                //write to entitlements.plist
                
                NSString *_entitlementFileName = [self _getFilePathWithPrefix:@"entitlements"];

                NSString * entitlementsPlistPath = [[SharedData sharedInstance].tempPath stringByAppendingPathComponent:_entitlementFileName];
                [entitlements writeToFile:entitlementsPlistPath atomically:YES];
                
                if (_entitlementsType == Normal) {
                    
                    [SharedData sharedInstance].normalEntitlementsPlistPath = entitlementsPlistPath;

                    _finishedBlock(TRUE, Normal);
                }else if (_entitlementsType == WatchKitExtension) {
                    
                    [SharedData sharedInstance].watchKitExtensionEntitlementsPlistPath = entitlementsPlistPath;
                    
                    _finishedBlock(TRUE, WatchKitExtension);
                    
                }else if (_entitlementsType == WatchKitApp){
                    
                    [SharedData sharedInstance].watchKitAppEntitlementsPlistPath = entitlementsPlistPath;
                    
                    _finishedBlock(TRUE, WatchKitApp);
                }
            }
        }
    }
}

- (NSString *) _getFilePathWithPrefix:(NSString *)filePrefix {
    
    if (_entitlementsType == Normal) {
        filePrefix = [filePrefix stringByAppendingString:@".plist"];
    }else if (_entitlementsType == WatchKitExtension) {
        filePrefix = [filePrefix stringByAppendingString:@"_watchkitextension.plist"];
    }else if (_entitlementsType == WatchKitApp){
        filePrefix = [filePrefix stringByAppendingString:@"_watchkitapp.plist"];
    }
    return filePrefix;
}
@end
