//
//  coderesignTools.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/15/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MGFDecodeicon : NSObject

+ (void)mgf_convertEncryptedImageDataToNormal:(NSString *)encryptedImagePath withNewFilePath:(NSString *)newFilePath withPy:(NSString *)pythonPath;

@end
