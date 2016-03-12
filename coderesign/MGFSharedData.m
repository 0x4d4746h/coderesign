//
//  SharedData.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFSharedData.h"

NSString *const minus_d     = @"-d";
NSString *const minus_p     = @"-p";
NSString *const minus_ex    = @"-ex";
NSString *const minus_wp    = @"-wp";
NSString *const minus_se    = @"-se";
NSString *const minus_cer   = @"-ci";
NSString *const minus_py    = @"-py";
NSString *const minus_h     = @"-h";

NSString *const kPayloadDirName         = @"Payload";
NSString *const kFrameworksDirName      = @"Frameworks";
NSString *const kPlugIns                = @"PlugIns";

NSString *const kDylib                  = @"dylib";
NSString *const kEntitlements           = @"entitlements";
NSString *const kApp                    = @"app";
NSString *const kAppex                  = @"appex";
NSString *const kFramework              = @"framework";

NSString *const kEmbedded_MobileProvision   = @"embedded.mobileprovision";
NSString *const kApple_security_group       = @"com.apple.security.application-groups";

NSString *const kInfo_plist                = @"Info.plist";

static MGFSharedData *_instance = NULL;

@implementation MGFSharedData


+ (MGFSharedData *)sharedInstance {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class]alloc]init];
        _instance.standardCommands = @[minus_d, minus_p, minus_ex,minus_wp, minus_se, minus_cer, minus_py];
        NSTimeInterval timestrap = [[NSDate date]timeIntervalSince1970];
        _instance.workingPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%f",timestrap]];
        _instance.libraryArray = [[NSMutableArray alloc]init];
    });
    
    return _instance;
}



@end
