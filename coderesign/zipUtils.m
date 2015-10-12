//
//  zipUtils.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/16/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "zipUtils.h"
#import "DebugLog.h"
#import "SharedData.h"


@interface zipUtils ()

@property (nonatomic, strong) NSTask *unzipTask;
@property (nonatomic, strong) NSTask *zipTask;
@property (nonatomic, copy) NSString *fileName;

@property (nonatomic, copy)ZipFinished zipFinishedBlock;
@property (nonatomic, copy)UnzipFinished unzipFinishedBlock;

@end

static zipUtils *_instance = NULL;

@implementation zipUtils

+ (zipUtils *)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[[self class]alloc]init];
    });
    
    return _instance;
}

/**
 * Zip Action
 */
- (void)doZipWithFinishedBlock:(ZipFinished)finishedBlock
{
    _zipFinishedBlock = finishedBlock;
    
    if ([SharedData sharedInstance].appPath) {
        NSString *sourcePath = [SharedData sharedInstance].crossedArguments[minus_d];
        NSArray *destinationPathComponents = [sourcePath pathComponents];
        NSString *destinationPath = @"";
        
        for (int i = 0; i < ([destinationPathComponents count]-1); i++) {
            destinationPath = [destinationPath stringByAppendingPathComponent:[destinationPathComponents objectAtIndex:i]];
        }
        
        _fileName = [sourcePath lastPathComponent];
        _fileName = [_fileName substringToIndex:([_fileName length] - ([[sourcePath pathExtension] length] + 1))];
        _fileName = [_fileName stringByAppendingString:@"-resigned"];
        _fileName = [_fileName stringByAppendingPathExtension:@"ipa"];
        
        destinationPath = [destinationPath stringByAppendingPathComponent:_fileName];
        
        _zipTask = [[NSTask alloc] init];
        [_zipTask setLaunchPath:@"/usr/bin/zip"];
        [_zipTask setCurrentDirectoryPath:[SharedData sharedInstance].workingPath];
        [_zipTask setArguments:[NSArray arrayWithObjects:@"-qry", destinationPath, @".", nil]];
        
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkZip:) userInfo:nil repeats:TRUE];
        
        
        NSString *zippingPath = [NSString stringWithFormat:@"Zipping to %@", destinationPath];
        [DebugLog showDebugLog:zippingPath withDebugLevel:Info];
        
        [_zipTask launch];
    }
}

- (void)checkZip:(NSTimer *)timer {
    if ([_zipTask isRunning] == 0) {
        [timer invalidate];
        _zipTask = nil;
        
        NSString *savedFile = [NSString stringWithFormat:@"Zipping done, file name is %@",_fileName];
        [DebugLog showDebugLog:savedFile withDebugLevel:Info];
        
        _zipFinishedBlock(TRUE);
    }
}

/**
 *
 * Unzip Action
 */
- (void)doUnZipWithFinishedBlock:(UnzipFinished)finishedBlock {
    [DebugLog showDebugLog:@"############################################################################ unzip ipa..." withDebugLevel:Info];
    
    _unzipFinishedBlock = finishedBlock;
    
    NSString *unzippath = [@"unzip ipa to " stringByAppendingString:[SharedData sharedInstance].workingPath];
    [DebugLog showDebugLog:unzippath withDebugLevel:Info];
    
    NSString *sourcePath = [SharedData sharedInstance].crossedArguments[minus_d];
    
    _unzipTask = [[NSTask alloc] init];
    
    [_unzipTask setLaunchPath:@"/usr/bin/unzip"];
    [_unzipTask setArguments:[NSArray arrayWithObjects:@"-o", @"-q", sourcePath, @"-d", [SharedData sharedInstance].workingPath, nil]];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:_instance selector:@selector(checkUnzip:) userInfo:nil repeats:TRUE];
    [_unzipTask launch];
}

- (void)checkUnzip:(NSTimer *)timer {
    if ([_unzipTask isRunning] == 0) {
        [timer invalidate];
        _unzipTask = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[[SharedData sharedInstance].workingPath stringByAppendingPathComponent:kPayloadDirName]]) {
            [DebugLog showDebugLog:Pass];
            
            _unzipFinishedBlock (TRUE);
            
        } else {
            [DebugLog showDebugLog:@"Unzip Failed" withDebugLevel:Error];
            _unzipFinishedBlock(FALSE);
        }
    }
}
@end
