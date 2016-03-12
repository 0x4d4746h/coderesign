//
//  MGFBaseObject.h
//  coderesign
//
//  Created by MiaoGuangfa on 3/11/16.
//  Copyright © 2016 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGFCodeResignDelegate.h"
#import "MGFSharedData.h"
#import "DebugLog.h"

@interface MGFBaseObject : NSObject

@property (nonatomic, weak) id<MGFCodeResignDelegate> codeResignDelegate;
@property (nonatomic, strong) MGFSharedData *mgfSharedData;

- (void) mgf_invokeDelegate:(id) obj withFinished:(BOOL) isFinished withObject:(id) object;

@end
