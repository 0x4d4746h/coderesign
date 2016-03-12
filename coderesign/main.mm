//
//  main.m
//  coderesign
//
//  Created by MiaoGuangfa on 7/24/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGFCodeResign.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [[MGFCodeResign sharedInstance] runCodeResignWithArgv:argv argumentsNumber: argc];
    }

    [[NSRunLoop currentRunLoop] run];
    return 0;
}
