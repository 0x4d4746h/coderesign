//
//  MGFSecurityDecodeMobileProvision.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/18/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGFBaseObject.h"

@interface MGFSecurityDecodeMobileProvision : MGFBaseObject

- (void) mgf_decodeEntitlementsFromMobileProvision:(NSString *)mobileProvisionFilePath withEntitlementsType:(EntitlementsType) entitlementsType;

@end
