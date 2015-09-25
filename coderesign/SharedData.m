//
//  SharedData.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "SharedData.h"

NSString *const KReplaceMobileProvisionNotification = @"key.replace.mobileProvision.notification";
NSString *const KCodeResignNotification = @"key.coderesign.notification";
NSString *const KCheckCPUNotification = @"key.checkCPU.notification";

NSString *const minus_d = @"-d";
NSString *const minus_p = @"-p";
//NSString *const minus_e = @"-e";
//NSString *const minus_id= @"-id";
NSString *const minus_cer = @"-ci";
NSString *const minus_py = @"-py";
NSString *const minus_h = @"-h";

//NSString *const DISTRIBUTION = @"Distribution";
NSString *const kPayloadDirName = @"Payload";
NSString *const kFrameworksDirName  = @"Frameworks";

static SharedData *_instance = NULL;

@implementation SharedData


+ (SharedData *)sharedInstance {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class]alloc]init];
        _instance.standardCommands = @[minus_d, minus_p, minus_cer, minus_py];
        _instance.workingPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.0x4d4746h.resign"];
    });
    
    return _instance;
}



@end
