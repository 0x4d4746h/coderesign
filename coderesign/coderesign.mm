//
//  coderesign.m
//  coderesign
//
//  Created by MiaoGuangfa on 7/24/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "coderesign.h"
#import "decompressIcon.h"
#import "SharedData.h"
#import "DebugLog.h"
#import "checkSystemEnvironments.h"
#import "checkAvailableCerts.h"
#import "checkCommandArguments.h"
#import "zipUtils.h"
#import "replaceMobileprovision.h"
#import "resignAction.h"
#import "checkAppCPUConstruction.h"
#import "Usage.h"
#import "securityEncodeDecodeMobileProvision.h"
#import "ModifyXcent.h"
#import "parseAppInfo.h"

@interface coderesign ()

@end

static coderesign *shared_coderesign_handler = NULL;

@implementation coderesign

+ (id)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared_coderesign_handler = [[[self class]alloc]init];
    });
    
    return shared_coderesign_handler;
}

- (void)resignWithArgv:(const char *[])argv argumentsNumber:(int)argc
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
        
    [DebugLog showDebugLog:@"coderesign task is running..." withDebugLevel:Info];

    if([checkCommandArguments checkArguments:argv number:argc]) {
        [self start];
    }
}

- (void)start
{
    if (![SharedData sharedInstance].isOnlyDecodeIcon) {
        
        /**
         * if need to resign ipa, dump entitlements at first.
         */
        NSString *_normalMobileProvisionPath            = [SharedData sharedInstance].crossedArguments[minus_p];
        NSString *_watchkitextensionMobileProvisionPath = [SharedData sharedInstance].crossedArguments[minus_ex];
        NSString *_watchkitappMobileProvisionPath       = [SharedData sharedInstance].crossedArguments[minus_wp];
        
        [DebugLog showDebugLog:@"############################################################################ Starting to dump entitlements from mobile provision file ..." withDebugLevel:Info];
        
        dispatch_group_t dumpEntitlementsGroup = dispatch_group_create();
        dispatch_group_enter(dumpEntitlementsGroup);
        
        [[securityEncodeDecodeMobileProvision sharedInstance]dumpEntitlementsFromMobileProvision:_normalMobileProvisionPath withEntitlementsType:Normal withBlock:^(BOOL isFinished, EntitlementsType type) {
            if (isFinished) {
                
                [DebugLog showDebugLog:@"normal app entitlements dump done, next to dump watchkit extension.." withDebugLevel:Info];

                [[securityEncodeDecodeMobileProvision sharedInstance]dumpEntitlementsFromMobileProvision:_watchkitextensionMobileProvisionPath withEntitlementsType:WatchKitExtension withBlock:^(BOOL isFinished, EntitlementsType type) {
                    if (isFinished) {
                        
                        [DebugLog showDebugLog:@"watchkit extension entitlements dump done, next to dump watchkit app.." withDebugLevel:Info];
                        
                        [[securityEncodeDecodeMobileProvision sharedInstance]dumpEntitlementsFromMobileProvision:_watchkitappMobileProvisionPath withEntitlementsType:WatchKitApp withBlock:^(BOOL isFinished, EntitlementsType type) {
                            if (isFinished) {
                                [DebugLog showDebugLog:@"All entitlements dump done, start to do next step..." withDebugLevel:Info];
                            }
                            
                            dispatch_group_leave(dumpEntitlementsGroup);
                        }];
                    }else{
                        dispatch_group_leave(dumpEntitlementsGroup);
                    }
                }];
            }else{
                dispatch_group_leave(dumpEntitlementsGroup);
                exit(0);
            }
        }];
        
        dispatch_group_notify(dumpEntitlementsGroup, dispatch_get_main_queue(), ^{
            [self _nextAction];
        });
    }else{
        [self _nextAction];
    }
}

- (void) _nextAction
{
    if ([checkSystemEnvironments doCheckSystemEnvironments]) {
        if ([SharedData sharedInstance].isOnlyDecodeIcon) {
            
            [[zipUtils sharedInstance]doUnZipWithFinishedBlock:^(BOOL isFinished) {
                if (isFinished) {
                    [[replaceMobileprovision sharedInstance]replaceWithFinishedBlock:^(BOOL isFinished) {
                        if (isFinished) {
                            
                            [[checkAppCPUConstruction sharedInstance]checkWithFinishedBlock:^(BOOL isFinished) {
                                if (isFinished) {
                                    [[resignAction sharedInstance]resign];
                                }
                            }];
                        }
                    }];
                }else{
                    exit(0);
                }
            }];
        }else{
            if ([checkAvailableCerts isExistAvailableCerts]) {
                [[zipUtils sharedInstance]doUnZipWithFinishedBlock:^(BOOL isFinished) {
                    if (isFinished) {
                        [[replaceMobileprovision sharedInstance]replaceWithFinishedBlock:^(BOOL isFinished) {
                            if (isFinished) {
                                if ([SharedData sharedInstance].isSupportWatchKitApp) {
                                    [[parseAppInfo sharedInstance]modifyWatchKitExtensionInfoPlistForNSExtension];
                                    [[parseAppInfo sharedInstance]modifyWatchKitAppCompanionID];
                                }
                                
                                
                                [[ModifyXcent sharedInstance]ModifyXcentWithFinishedBlock:^(BOOL isFinished) {
                                    if (isFinished) {
                                        [[checkAppCPUConstruction sharedInstance]checkWithFinishedBlock:^(BOOL isFinished) {
                                            if (isFinished) {
                                                [[resignAction sharedInstance]resign];
                                            }
                                        }];
                                    }
                                }];
                            }
                        }];
                    }else{
                        exit(0);
                    }
                }];
            }
        }
    }
}
@end
