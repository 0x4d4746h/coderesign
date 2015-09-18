//
//  securityEncodeDecodeMobileProvision.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/18/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface securityEncodeDecodeMobileProvision : NSObject
+ (securityEncodeDecodeMobileProvision *)sharedInstance;
- (void) dumpEntitlements;
- (void) decode;
- (void) encode;
@end
