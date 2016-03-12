//
//  zipUtils.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGFBaseObject.h"

FOUNDATION_EXPORT NSString *const kZip;
FOUNDATION_EXPORT NSString *const kUnzip;

@interface MGFZipUtils : MGFBaseObject

- (void) mgf_doZip;
- (void) mgf_doUnZip;

@end
