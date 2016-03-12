//
//  coderesign.m
//  coderesign
//
//  Created by MiaoGuangfa on 7/24/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFCodeResign.h"
#import "MGFSharedData.h"
#import "MGFCheckSystemEnvironments.h"
#import "MGFCheckCommandArguments.h"
#import "MGFCodeResignDelegate.h"
#import "MGFSecurityDecodeMobileProvision.h"
#import "MGFCheckAvailableCerts.h"
#import "DebugLog.h"
#import "MGFZipUtils.h"
#import "MGFCheckInHouseType.h"
#import "MGFParseAppInfo.h"
#import "MGFReplaceMobileprovision.h"
#import "MGFParsePlayload.h"
#import "MGFCheckCPUConstruction.h"
#import "MGFResign.h"
#import "Usage.h"


@interface MGFCodeResign () <MGFCodeResignDelegate>

@property (nonatomic, strong) MGFSharedData *sharedData;

@end

static MGFCodeResign *shared_coderesign_handler = NULL;

@implementation MGFCodeResign

+ (id)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared_coderesign_handler = [[[self class]alloc]init];
        shared_coderesign_handler.sharedData = [MGFSharedData sharedInstance];
    });
    
    return shared_coderesign_handler;
}

/**
 * start to run code resign precess
 */
- (void)runCodeResignWithArgv:(const char *[])argv argumentsNumber:(int)argc
{
    if (argc == 1) {
        [Usage print:nil];
        exit(0);
    }else if (argc == 2){
        NSString *_h = [NSString stringWithUTF8String:argv[1]];
        if ([_h  isEqual: @"-h"]) {
            [Usage print:_h];
            exit(0);
        }
    }
        
    [DebugLog showDebugLog:@"coderesign task is running..." withDebugLevel:Debug];
    
    //First: CheckCommandArguments, sync method
    [self _mgf_checkCommandArguments:argv withNumber:argc];
    
    //Second:Check System environments, sync method
    [self _mgf_checkSystemEnvironments];
    
    //Third:Check certificates, sync method
    [self _mgf_checkCertificates];
    
    //Fourth: Decode the passed entitlement files, include thread, concurrent, async method
    [self _mgf_decodeEntitlements];
}

/**
 * Start to decode entitlements for the passed mobileprovision files
 */
- (void) _mgf_decodeEntitlements {
    
    @synchronized(_sharedData.workingPath) {
        //remove the cache file at first
        if ([[NSFileManager defaultManager]fileExistsAtPath:_sharedData.workingPath]){
            [[NSFileManager defaultManager]removeItemAtPath:_sharedData.workingPath error:nil];
        }
    }
   
    MGFSecurityDecodeMobileProvision *_mgfSecurityDecodeObj = [[MGFSecurityDecodeMobileProvision alloc]init];
    
    
    [DebugLog showDebugLog:@"############################################################################ Starting to dump entitlements from mobile provision file ..." withDebugLevel:Debug];
    /**
     * if need to resign ipa, dump entitlements at first.
     */
    NSString *_normalMobileProvisionPath            = _sharedData.crossedArguments[minus_p];
    NSString *_watchkitextensionMobileProvisionPath = _sharedData.crossedArguments[minus_ex];
    NSString *_watchkitappMobileProvisionPath       = _sharedData.crossedArguments[minus_wp];
    NSString *_sharedExtentionMobileProvisionPath   = _sharedData.crossedArguments[minus_se];
    
    _mgfSecurityDecodeObj.codeResignDelegate = self;
    
    dispatch_queue_t queue = dispatch_queue_create("com.decode.mobileprovision", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        [_mgfSecurityDecodeObj mgf_decodeEntitlementsFromMobileProvision:_normalMobileProvisionPath withEntitlementsType:NormalEntitlement];
    });
    dispatch_async(queue, ^{
        [_mgfSecurityDecodeObj mgf_decodeEntitlementsFromMobileProvision:_watchkitextensionMobileProvisionPath withEntitlementsType:WatchKitExtensionEntitlement];
    });
    dispatch_async(queue, ^{
        [_mgfSecurityDecodeObj mgf_decodeEntitlementsFromMobileProvision:_watchkitappMobileProvisionPath withEntitlementsType:WatchKitAppEntitlement];
    });
    dispatch_async(queue, ^{
        [_mgfSecurityDecodeObj mgf_decodeEntitlementsFromMobileProvision:_sharedExtentionMobileProvisionPath withEntitlementsType:SharedExtensionEntitlement];
    });
    
    dispatch_barrier_async(queue, ^{
        [DebugLog showDebugLog:@"All entitlements dump done, start to do next step..." withDebugLevel:Debug];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self MGFCodeResignDelegate:_mgfSecurityDecodeObj withFinished:TRUE withObject:nil];
        });
    });
}

#pragma MGFCodeResignDelegate
- (void)MGFCodeResignDelegate:(id)obj withFinished:(BOOL)isFinished withObject:(id)object
{
    NSLog(@"%s, %@, %d, %@", __FUNCTION__, obj, isFinished, object);
    
    /**
     * if action is success, then show the all pass log and continue
     * otherwise, exit current runloop
     */
    if (isFinished) {
        [DebugLog showDebugLog:AllPass];
    } else {
        exit(0);
    }
    
    //Continue the next action.
    if ([obj isKindOfClass:[MGFSecurityDecodeMobileProvision class]] ) {
        
        //Fifth: UnZip IPA, async method
        [self _mgf_doUnZip];
        
    }else if ([obj isKindOfClass:[MGFZipUtils class]]) {
        NSString *sObj =  (NSString*) object;
        if ([sObj isEqualToString:kUnzip]) {
            
            //Unzip done, to do Sixth step. sync method
            [self _mgf_parsePlayload];
        
        }else if ([sObj isEqualToString:kZip]) {
            //All resign action is done.
            //clear the cache data, and exit now
            [self __mgf_done];
        }
    }else if ([obj isKindOfClass:[MGFParsePlayload class]]) {
        
        //Parse playload done, to do Seventh step
        [self _mgf_checkInHouseType];
        
    }else if ([obj isKindOfClass:[MGFCheckInHouseType class]]) {
        
        if (_sharedData.isInHouseType) {
            //parse app info
            [self _mgf_parseAppInfo];
        } else {
            [self _mgf_replaceMobileProvision];
        }
        
    }else if ([obj isKindOfClass:[MGFReplaceMobileprovision class]]) {
        
        //parse app info
        [self _mgf_parseAppInfo];
        
    }else if ([obj isKindOfClass:[MGFParseAppInfo class]]) {
        
        //check cpu construction
        [self _mgf_checkCPUConstruction];
    
    }else if ([obj isKindOfClass:[MGFCheckCPUConstruction class]]) {
        
        if (_sharedData.isInHouseType) {
            //zip package
            [self _mgf_doZip];
        }else {
            //resign
            [self _mgf_resign];
        }
    }else if ([obj isKindOfClass:[MGFResign class]]) {
        //zip package, done
        [self _mgf_doZip];
    }
}


#pragma private methods
- (void)__mgf_done {
    [[NSFileManager defaultManager] removeItemAtPath:_sharedData.workingPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:_sharedData.tempPath error:nil];
    [DebugLog showDebugLog:@"coderesign successful" withDebugLevel:Debug];
    
    NSDictionary *_resignedIPA = @{@"ResignedIPA"       :   _sharedData.resignedIPAPath};
    NSData *objData = [NSJSONSerialization dataWithJSONObject:_resignedIPA options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:objData encoding:NSUTF8StringEncoding];
    
    NSString *_result = [@"<ResignedIPA>" stringByAppendingFormat:@"%@</ResignedIPA>",jsonString];
    [DebugLog showDebugLog:_result withDebugLevel:Info];
    [DebugLog showDebugLog:AllDone];
    exit(0);
}


/**
 * Alloc check command instance
 */
- (void) _mgf_checkCommandArguments:(const char*[]) argv withNumber:(int) argc {
    MGFCheckCommandArguments *_mgfCheckCommandArgumentsObj = (MGFCheckCommandArguments *)[self _mgf_newInstance:[MGFCheckCommandArguments class]];
    if (_mgfCheckCommandArgumentsObj) {
        [_mgfCheckCommandArgumentsObj mgf_checkArguments:argv number:argc];
    }
}

/**
 * Alloc check system environments instance
 */
- (void) _mgf_checkSystemEnvironments {
    MGFCheckSystemEnvironments *_mgfCheckSystemEnvirObj = (MGFCheckSystemEnvironments *)[self _mgf_newInstance:[MGFCheckSystemEnvironments class]];
    if (_mgfCheckSystemEnvirObj && [_mgfCheckSystemEnvirObj respondsToSelector:@selector(mgf_checkSystemEnvironments)]) {
        [_mgfCheckSystemEnvirObj mgf_checkSystemEnvironments];
    }
}

/**
 * Alloc check available certificates instance
 */
- (void)_mgf_checkCertificates {
    MGFCheckAvailableCerts *_mgfCheckCertsObj = (MGFCheckAvailableCerts *)[self _mgf_newInstance:[MGFCheckAvailableCerts class]];
    if (_mgfCheckCertsObj) {
        [_mgfCheckCertsObj mgf_checkExistAvailableCerts];
    }
}

/**
 * Alloc zip instance
 */
- (void) _mgf_doUnZip {
    MGFZipUtils *_mgfZipObj = (MGFZipUtils *)[self _mgf_newInstance:[MGFZipUtils class]];
    if (_mgfZipObj) {
        [_mgfZipObj mgf_doUnZip];
    }
}

/**
 * Alloc parse playload instance
 */
- (void) _mgf_parsePlayload {
    MGFParsePlayload *_mgfParsePlaylaodObj = (MGFParsePlayload *)[self _mgf_newInstance:[MGFParsePlayload class]];
    if (_mgfParsePlaylaodObj) {
        [_mgfParsePlaylaodObj mgf_parsePlayload];
    }
}

/**
 * Alloc check inhouse type instance
 */
- (void)_mgf_checkInHouseType {
    MGFCheckInHouseType *_mgfCheckInHouseTypeObj = (MGFCheckInHouseType *)[self _mgf_newInstance:[MGFCheckInHouseType class]];
    if (_mgfCheckInHouseTypeObj) {
        [_mgfCheckInHouseTypeObj mgf_checkIfInHouseType];
    }
}

/**
 * Alloc replace mobile provision instance
 */
- (void)_mgf_replaceMobileProvision {
    MGFReplaceMobileprovision *_mgfReplaceMobileProvisionObj = (MGFReplaceMobileprovision *)[self _mgf_newInstance:[MGFReplaceMobileprovision class]];
    if (_mgfReplaceMobileProvisionObj) {
        [_mgfReplaceMobileProvisionObj mgf_replaceMobileProvision];
    }
}

/**
 * Alloc parse app info instance
 */
- (void)_mgf_parseAppInfo {
    MGFParseAppInfo *_mgfParseAppInfoObj = (MGFParseAppInfo *)[self _mgf_newInstance:[MGFParseAppInfo class]];
    if (_mgfParseAppInfoObj) {
        [_mgfParseAppInfoObj mgf_parseAppInfo];
    }
}

/**
 * Alloc check cpu construction instance
 */
- (void)_mgf_checkCPUConstruction {
    MGFCheckCPUConstruction *_mgfCheckCPUConstructionObj = (MGFCheckCPUConstruction *)[self _mgf_newInstance:[MGFCheckCPUConstruction class]];
    if (_mgfCheckCPUConstructionObj) {
        [_mgfCheckCPUConstructionObj mgf_checkCPUContruction];
    }
}

/**
 * Alloc resign instance
 */
- (void)_mgf_resign {
    MGFResign *_mgfResignObj = (MGFResign *)[self _mgf_newInstance:[MGFResign class]];
    if (_mgfResignObj) {
        [_mgfResignObj mgf_resign];
    }
}

/**
 * Alloc do zip instance
 */
- (void)_mgf_doZip {
    MGFZipUtils *_mgfZipObj = (MGFZipUtils *)[self _mgf_newInstance:[MGFZipUtils class]];
    if (_mgfZipObj) {
        [_mgfZipObj mgf_doZip];
    }
}

/**
 * Alloc an id type instance
 */
- (MGFBaseObject *)_mgf_newInstance:(Class) objClass {
    if (objClass) {
        MGFBaseObject *obj = [[objClass alloc]init];
        obj.codeResignDelegate = self;
        return obj;
    }
    return nil;
}
@end
