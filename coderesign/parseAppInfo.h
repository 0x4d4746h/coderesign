//
//  parseAppInfo.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/17/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SharedData.h"

@interface parseAppInfo : NSObject

+ (parseAppInfo *) sharedInstance;

- (void) parse:(NSString *)infoPlistPath withAppType:(AppType) type;
- (void) modifyWatchKitExtensionInfoPlistForNSExtension;
- (void)modifyWatchKitAppCompanionID;
@end
