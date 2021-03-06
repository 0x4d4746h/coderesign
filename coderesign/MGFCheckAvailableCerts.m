//
//  checkAvailableCerts.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFCheckAvailableCerts.h"

@implementation MGFCheckAvailableCerts

- (void)mgf_checkExistAvailableCerts {
    [DebugLog showDebugLog:@"############################################################################ Checking Signing Certificate IDs from keychain tools..." withDebugLevel:Debug];
    
    NSTask *certTask = [[NSTask alloc] init];
    [certTask setLaunchPath:@"/usr/bin/security"];
    [certTask setArguments:[NSArray arrayWithObjects:@"find-identity", @"-v", @"-p", @"codesigning", nil]];
    
    NSPipe *pipe=[NSPipe pipe];
    [certTask setStandardOutput:pipe];
    [certTask setStandardError:pipe];
    NSFileHandle *handle=[pipe fileHandleForReading];
    
    [certTask launch];
    NSString *securityResult = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    
    if (securityResult == nil || securityResult.length < 1) {
        [DebugLog showDebugLog:@"There are no certificates files installed in keychain." withDebugLevel:Error];
        [self mgf_invokeDelegate:self withFinished:FALSE withObject:nil];
    }
    
    [DebugLog showDebugLog:securityResult withDebugLevel:Debug];
    
    NSArray *rawResult = [securityResult componentsSeparatedByString:@"\""];
    NSMutableArray *cer_results = [NSMutableArray new];
    for (int i = 0; i <= [rawResult count] - 2; i+=2) {
        
        if (rawResult.count - 1 < i + 1) {
            // Invalid array, don't add an object to that position
        } else {
            // Valid object
            [cer_results addObject:[rawResult objectAtIndex:i+1]];
        }
    }
    
    NSString *cer_index_distribution   = self.mgfSharedData.crossedArguments[minus_cer];

    NSUInteger _count = [cer_results count];
    for (int i=0; i< _count; i++) {
        NSString *cer_name_ = cer_results[i];
        
        // NSRange distribution_ns_range = [cer_name_ rangeOfString:DISTRIBUTION];
        NSRange cer_index_range = [cer_name_ rangeOfString:cer_index_distribution];
        
        if (cer_index_range.length > 0) {
            self.mgfSharedData.resignedCerName = cer_name_;
            NSString *_matchedCer = [NSString stringWithFormat:@"provision profile <%@> will be used to resign", self.mgfSharedData.resignedCerName];
            [DebugLog showDebugLog:_matchedCer withDebugLevel:Debug];
            
            [DebugLog showDebugLog:Pass];
        }
    }
    
    if (!self.mgfSharedData.resignedCerName || [self.mgfSharedData.resignedCerName length] == 0) {
        [DebugLog showDebugLog:@"There is no matched certificates file installed in keychain." withDebugLevel:Error];
        [self mgf_invokeDelegate:self withFinished:FALSE withObject:nil];
    }
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}
@end
