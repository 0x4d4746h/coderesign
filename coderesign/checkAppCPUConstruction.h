//
//  checkAppCPUConstruction.h
//  coderesign
//
//  Created by MiaoGuangfa on 9/17/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^CheckCPUFinishedBlock)(BOOL isFinished);

@interface checkAppCPUConstruction : NSObject

+ (checkAppCPUConstruction *) sharedInstance;

- (void) checkWithFinishedBlock:(CheckCPUFinishedBlock) finishedBlock;
@end
