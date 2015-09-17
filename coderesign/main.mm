//
//  main.m
//  coderesign
//
//  Created by MiaoGuangfa on 7/24/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "coderesign.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [[coderesign sharedInstance] resignWithArgv:argv argumentsNumber: argc];
    }

    [[NSRunLoop currentRunLoop] run];
    return 0;
}
