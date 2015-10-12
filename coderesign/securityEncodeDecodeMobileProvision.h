//
//  securityEncodeDecodeMobileProvision.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/18/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SharedData.h"

typedef void(^finished)(BOOL isFinished, EntitlementsType type);

@interface securityEncodeDecodeMobileProvision : NSObject

+ (securityEncodeDecodeMobileProvision *)sharedInstance;

- (void) dumpEntitlementsFromMobileProvision:(NSString *)mobileProvisionFilePath withEntitlementsType:(EntitlementsType) entitlementsType withBlock:(finished) finishedBlock;

@end
