//
//  MGFBaseObject.m
//  coderesign
//
//  Created by MiaoGuangfa on 3/11/16.
//  Copyright © 2016 MiaoGuangfa. All rights reserved.
//

#import "MGFBaseObject.h"


@implementation MGFBaseObject

- (instancetype)init {
    self = [super init];
    if (self) {
        self.codeResignDelegate = nil;
        self.mgfSharedData = [MGFSharedData sharedInstance];
    }
    return self;
}


- (void) mgf_invokeDelegate:(id) obj withFinished:(BOOL) isFinished withObject:(id) object {
    if (self.codeResignDelegate && [self.codeResignDelegate respondsToSelector:@selector(MGFCodeResignDelegate:withFinished:withObject:)]) {
        [self.codeResignDelegate MGFCodeResignDelegate:obj withFinished:isFinished withObject:object];
    }
}
@end
