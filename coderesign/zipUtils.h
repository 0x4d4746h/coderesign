//
//  zipUtils.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^UnzipFinished)(BOOL isFinished);
typedef void(^ZipFinished)(BOOL isFinished);

@interface zipUtils : NSObject

+ (zipUtils *)sharedInstance;

- (void) doZipWithFinishedBlock:(ZipFinished)finishedBlock;
- (void) doUnZipWithFinishedBlock:(UnzipFinished)finishedBlock;

@end
