//
//  SharedData.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const minus_d;
FOUNDATION_EXPORT NSString *const minus_p;
FOUNDATION_EXPORT NSString *const minus_ex;
FOUNDATION_EXPORT NSString *const minus_wp;
FOUNDATION_EXPORT NSString *const minus_cer;
FOUNDATION_EXPORT NSString *const minus_py;
FOUNDATION_EXPORT NSString *const minus_h;

FOUNDATION_EXPORT NSString *const kPayloadDirName;
FOUNDATION_EXPORT NSString *const kFrameworksDirName;
FOUNDATION_EXPORT NSString *const kPlugIns;


typedef enum {
    Replace_MobileProvision = 0,
    Code_Resign,
    CPU_CHECK
    
}NotificationType;

typedef enum {
    Normal = 0,
    WatchKitExtension,
    WatchKitApp
}EntitlementsType;

typedef enum {
    MainApp = 0,
    Extension,
    WatchApp,
    Swift
}AppType;

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


//the flag for different actions
@property (nonatomic, assign) BOOL isOnlyDecodeIcon;
@property (nonatomic, assign) BOOL isResignAndDecode;
@property (nonatomic, assign) BOOL isOnlyResign;

@property (nonatomic, copy) NSString *watchKitExtensionPath;
@property (nonatomic, copy) NSString *watchKitAppPath;
@property (nonatomic, copy) NSString *swiftFrameworksPath;
@property (nonatomic, copy) NSString *plugInsPath;
@property (nonatomic, copy) NSString *extensionEntitlementsPath;

@property (nonatomic, strong) NSMutableArray *swiftFrameworks;

/**
 * define the public entitlements plist path veriables
 */
@property (nonatomic, copy) NSString *watchKitExtensionEntitlementsPlistPath;
@property (nonatomic, copy) NSString *watchKitAppEntitlementsPlistPath;
@property (nonatomic, copy) NSString *normalEntitlementsPlistPath;

@property (nonatomic, copy) NSString *watchKitAppID;
@property (nonatomic, copy) NSString *mainAppID;

/**
 * define the public support veriables
 */
@property (nonatomic, assign) BOOL isSupportWatchKitExtension;
@property (nonatomic, assign) BOOL isSupportWatchKitApp;
@property (nonatomic, assign) BOOL isSupportSwift;
@property (nonatomic, assign) BOOL isSupportAppGroup;
@property (nonatomic, assign) BOOL isSupportExtensionEntitlements;
@property (nonatomic, assign) BOOL isInHouseType;

+ (SharedData *) sharedInstance;

@end
