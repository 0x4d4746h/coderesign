//
//  coderesign.m
//  coderesign
//
//  Created by MiaoGuangfa on 7/24/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "coderesign.h"
#import "decompressIcon.h"
#import "SharedData.h"
#import "DebugLog.h"
#import "checkSystemEnvironments.h"
#import "checkAvailableCerts.h"
#import "checkCommandArguments.h"
#import "zipUtils.h"
#import "replaceMobileprovision.h"
#import "resignAction.h"


@interface coderesign ()

- (void) NotificationEvent:(NSNotification *)notification;

@end

static coderesign *shared_coderesign_handler = NULL;

@implementation coderesign

+ (id)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared_coderesign_handler = [[[self class]alloc]init];
        
        [[NSNotificationCenter defaultCenter]addObserver:shared_coderesign_handler selector:@selector(NotificationEvent:) name:KReplaceMobileProvisionNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:shared_coderesign_handler selector:@selector(NotificationEvent:) name:KCodeResignNotification object:nil];
    });
    
    return shared_coderesign_handler;
}

- (void)resignWithArgv:(const char *[])argv argumentsNumber:(int)argc
{
    [DebugLog showDebugLog:@"coderesign task is running..." withDebugLevel:Info];

    if([checkCommandArguments checkArguments:argv number:argc]) {
        [self start];
    }
}

- (void)start
{
    if ([checkSystemEnvironments doCheckSystemEnvironments]) {
        if ([checkAvailableCerts isExistAvailableCerts]) {
            [[zipUtils sharedInstance]doUnZip];
        }
    }
}


#pragma mark - private methods
- (void)NotificationEvent:(NSNotification *)notification
{
    NSNumber *_number = notification.object;
    NotificationType _type = (NotificationType)[_number intValue];
    if (_type == Replace_MobileProvision) {
        [[replaceMobileprovision sharedInstance]replace];
    }else if (_type == Code_Resign) {
        [[resignAction sharedInstance]resign];
    }
}

@end
