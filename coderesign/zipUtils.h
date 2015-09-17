//
//  zipUtils.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface zipUtils : NSObject

+ (zipUtils *)sharedInstance;

- (void) doZip;
- (void) doUnZip;

@end
