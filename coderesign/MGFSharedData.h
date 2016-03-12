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
FOUNDATION_EXPORT NSString *const minus_se;
FOUNDATION_EXPORT NSString *const minus_cer;
FOUNDATION_EXPORT NSString *const minus_py;
FOUNDATION_EXPORT NSString *const minus_h;

FOUNDATION_EXPORT NSString *const kPayloadDirName;
FOUNDATION_EXPORT NSString *const kFrameworksDirName;
FOUNDATION_EXPORT NSString *const kPlugIns;

FOUNDATION_EXPORT NSString *const kDylib;
FOUNDATION_EXPORT NSString *const kEntitlements;
FOUNDATION_EXPORT NSString *const kApp;
FOUNDATION_EXPORT NSString *const kAppex;
FOUNDATION_EXPORT NSString *const kFramework;

FOUNDATION_EXPORT NSString *const kEmbedded_MobileProvision;
FOUNDATION_EXPORT NSString *const kApple_security_group;

FOUNDATION_EXPORT NSString *const kInfo_plist;

typedef enum {
    Replace_MobileProvision = 0,
    Code_Resign,
    CPU_CHECK
    
}NotificationType;

typedef enum {
    NormalEntitlement = 0,
    WatchKitExtensionEntitlement,
    WatchKitAppEntitlement,
    SharedExtensionEntitlement
}EntitlementsType;

typedef enum {
    MainApp = 0,
    Extension,
    WatchApp,
    Swift,
    SharedExtension
}AppType;

@interface MGFSharedData : NSObject

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
@property (nonatomic, assign) BOOL isResignAndDecode;

@property (nonatomic, copy) NSString *watchKitExtensionPath;
@property (nonatomic, copy) NSString *watchKitAppPath;
//@property (nonatomic, copy) NSString *libraryPath;
@property (nonatomic, copy) NSString *plugInsPath;
@property (nonatomic, copy) NSString *watchKitExtensionEntitlementsPath;
@property (nonatomic, copy) NSString *sharedExtensionEntitlementsPath;
@property (nonatomic, copy) NSString *sharedExtensionPath;

@property (nonatomic, copy) NSString *origanizationalUnit;
@property (nonatomic, copy) NSString *resignedIPAPath;

@property (nonatomic, strong) NSMutableArray *libraryArray;

/**
 * define the public entitlements plist path veriables
 */
@property (nonatomic, copy) NSString *watchKitExtensionEntitlementsPlistPath;
@property (nonatomic, copy) NSString *watchKitAppEntitlementsPlistPath;
@property (nonatomic, copy) NSString *normalEntitlementsPlistPath;
@property (nonatomic, copy) NSString *sharedExtensionEntitlementsPlistPath;

@property (nonatomic, copy) NSString *watchKitAppID;
@property (nonatomic, copy) NSString *mainAppID;
@property (nonatomic, copy) NSString *watchKitExtensionID;
@property (nonatomic, copy) NSString *sharedExtensionID;

/**
 * define the public support veriables
 */
@property (nonatomic, assign) BOOL isSupportWatchKitExtension;
@property (nonatomic, assign) BOOL isSupportWatchKitApp;
@property (nonatomic, assign) BOOL isSupportLibrary;
@property (nonatomic, assign) BOOL isSupportAppGroup;
@property (nonatomic, assign) BOOL isInHouseType;
@property (nonatomic, assign) BOOL isSupportSharedExtension;

@property (nonatomic, copy) NSString *normalDecodeMobileProvisionPlistPath;

+ (MGFSharedData *) sharedInstance;

@end
