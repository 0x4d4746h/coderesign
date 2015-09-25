//
//  SharedData.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString *const KReplaceMobileProvisionNotification;
FOUNDATION_EXTERN NSString *const KCodeResignNotification;
FOUNDATION_EXPORT NSString *const KCheckCPUNotification;

FOUNDATION_EXPORT NSString *const minus_d;
FOUNDATION_EXPORT NSString *const minus_p;
//FOUNDATION_EXPORT NSString *const minus_e;
//FOUNDATION_EXPORT NSString *const minus_id;
FOUNDATION_EXPORT NSString *const minus_cer;
FOUNDATION_EXPORT NSString *const minus_py;
FOUNDATION_EXPORT NSString *const minus_h;

//FOUNDATION_EXPORT NSString *const DISTRIBUTION;
FOUNDATION_EXPORT NSString *const kPayloadDirName;
FOUNDATION_EXPORT NSString *const kFrameworksDirName;

typedef enum {
    Replace_MobileProvision = 0,
    Code_Resign,
    CPU_CHECK
    
}NotificationType;

@interface SharedData : NSObject

//Use to check input arguments
@property (nonatomic, strong) NSArray *standardCommands;

//input arguments
@property (nonatomic, strong) NSDictionary *crossedArguments;

//working path for NSTask
@property (nonatomic, copy) NSString *workingPath;

@property (nonatomic, copy) NSString *appPath;

@property (nonatomic, copy) NSString *resignedCerName;

@property (nonatomic, copy) NSString *tempPath;
@property (nonatomic, copy) NSString *commandPath;
@property (nonatomic, copy) NSString *entitlementsPlistPath;
+ (SharedData *) sharedInstance;

@end
