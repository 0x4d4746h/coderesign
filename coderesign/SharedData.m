//
//  SharedData.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "SharedData.h"

NSString *const minus_d     = @"-d";
NSString *const minus_p     = @"-p";
NSString *const minus_ex    = @"-ex";
NSString *const minus_wp    = @"-wp";
NSString *const minus_cer   = @"-ci";
NSString *const minus_py    = @"-py";
NSString *const minus_h     = @"-h";

NSString *const kPayloadDirName         = @"Payload";
NSString *const kFrameworksDirName      = @"Frameworks";
NSString *const kPlugIns                = @"PlugIns";

static SharedData *_instance = NULL;

@implementation SharedData


+ (SharedData *)sharedInstance {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class]alloc]init];
        _instance.standardCommands = @[minus_d, minus_p, minus_ex,minus_wp, minus_cer, minus_py];
        _instance.workingPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.0x4d4746h.resign"];
        _instance.swiftFrameworks = [[NSMutableArray alloc]init];
    });
    
    return _instance;
}



@end
