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
        
        //Test code
        //const char* test_argv[] = {"/Users/miaoguangfa/Desktop/codesign", "-d", "app", "-p", "mobileprovision", "-e", "entitlements", "-id", "com.0x4d4746h.coderesign"};
       // int test_argc = sizeof(&test_argv);
        //int argcs = argc;

        [[coderesign sharedInstance] resignWithArgv:argv argumentsNumber: argc];
    }

    [[NSRunLoop currentRunLoop] run];
    return 0;
}
