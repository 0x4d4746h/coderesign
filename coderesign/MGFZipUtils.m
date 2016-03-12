//
//  zipUtils.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "MGFZipUtils.h"

NSString *const kZip = @"zip";
NSString *const kUnzip = @"unzip";

@interface MGFZipUtils ()

@property (nonatomic, strong) NSTask *unzipTask;
@property (nonatomic, strong) NSTask *zipTask;
@property (nonatomic, copy) NSString *fileName;

@end


@implementation MGFZipUtils

/**
 * Zip Action
 */
- (void)mgf_doZip {

    NSString *sourcePath = self.mgfSharedData.crossedArguments[minus_d];
    NSArray *destinationPathComponents = [sourcePath pathComponents];
    NSString *destinationPath = @"";
    
    for (int i = 0; i < ([destinationPathComponents count]-1); i++) {
        destinationPath = [destinationPath stringByAppendingPathComponent:[destinationPathComponents objectAtIndex:i]];
    }
    
    NSString *rename_indicator;
    NSString *_origanizational_util = self.mgfSharedData.origanizationalUnit;
    if (_origanizational_util == nil || [_origanizational_util isEqualToString:@""]) {
        rename_indicator = @"-resigned";
    }else{
        rename_indicator = [@"-" stringByAppendingString:_origanizational_util];
    }
    
    _fileName = [sourcePath lastPathComponent];
    _fileName = [_fileName substringToIndex:([_fileName length] - ([[sourcePath pathExtension] length] + 1))];
    _fileName = [_fileName stringByAppendingString:rename_indicator];
    _fileName = [_fileName stringByAppendingPathExtension:@"ipa"];
    
    destinationPath = [destinationPath stringByAppendingPathComponent:_fileName];
    
    _zipTask = [[NSTask alloc] init];
    [_zipTask setLaunchPath:@"/usr/bin/zip"];
    [_zipTask setCurrentDirectoryPath:[MGFSharedData sharedInstance].workingPath];
    [_zipTask setArguments:[NSArray arrayWithObjects:@"-qry", destinationPath, @".", nil]];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkZip:) userInfo:nil repeats:TRUE];
    
    
    NSString *zippingPath = [NSString stringWithFormat:@"Zipping to %@", destinationPath];
    self.mgfSharedData.resignedIPAPath = destinationPath;
    
    [DebugLog showDebugLog:zippingPath withDebugLevel:Debug];
    
    [_zipTask launch];
}

- (void)checkZip:(NSTimer *)timer {
    if ([_zipTask isRunning] == 0) {
        [timer invalidate];
        _zipTask = nil;
        
        NSString *savedFile = [NSString stringWithFormat:@"Zipping done, file name is %@",_fileName];
        [DebugLog showDebugLog:savedFile withDebugLevel:Debug];
        [self mgf_invokeDelegate:self withFinished:TRUE withObject:kZip];
    }
}

/**
 *
 * Unzip Action
 */
- (void)mgf_doUnZip {
    [DebugLog showDebugLog:@"############################################################################ tar ipa..." withDebugLevel:Debug];
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:self.mgfSharedData.workingPath]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:self.mgfSharedData.workingPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *unzippath = [@"tar ipa to " stringByAppendingString:self.mgfSharedData.workingPath];
    [DebugLog showDebugLog:unzippath withDebugLevel:Debug];
    
    NSString *sourcePath = self.mgfSharedData.crossedArguments[minus_d];
    
    _unzipTask = [[NSTask alloc] init];
    
    [_unzipTask setLaunchPath:@"/usr/bin/tar"];
    [_unzipTask setArguments:[NSArray arrayWithObjects:@"-x", @"-f", sourcePath, @"-C", self.mgfSharedData.workingPath, nil]];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkUnzip:) userInfo:nil repeats:TRUE];
    [_unzipTask launch];
}

- (void)checkUnzip:(NSTimer *)timer {
    if ([_unzipTask isRunning] == 0) {
        [timer invalidate];
        _unzipTask = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self.mgfSharedData.workingPath stringByAppendingPathComponent:kPayloadDirName]]) {
            [self mgf_invokeDelegate:self withFinished:TRUE withObject:kUnzip];
        } else {
            [DebugLog showDebugLog:@"tar Failed" withDebugLevel:Error];
            [self mgf_invokeDelegate:self withFinished:FALSE withObject:nil];
        }
    }
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}
@end
