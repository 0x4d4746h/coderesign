//
//  Usage.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/17/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "Usage.h"

@interface Usage ()

+ (void) log;
@end

@implementation Usage

+ (void)print:(NSString *)option
{
    if (option == nil || [option  isEqual: @"-h"]) {
        [Usage log];
    }
}

+ (void)log {
    printf("\n                        CodeResign Tool General Commands Manual\nAUTHOR:\n       MiaoGuangfa(0x4d4746h@gmail.com, @0x4d4746h)\n\nNAME:\n     coderesign -- resign the specific ipa file with yourself provisioning profile\n\n");
    printf("SUPPORT LIST:\n     Support decompress the icon file from ipa.\n     Support check CPU construction for app.\n     Support dump the specific app info.\n     Support resign ipa file for Individual & Enterprise provision profile that related to developer or distribution cert.\n");
    printf("\nHOW TO USE:\n     coderesign -d /you/ipa/path/xx.ipa -p your_distribution.mobileprovision -e your_entitlements.plist -id com.your.newbundleID -ci certificates_index -py your-python\n");
    printf("\nONE MORE THING:\n       <1> If you want to resign the third ipa package with Individual distribution provision profile.\n\n       option -ci: App ID prefix should be passed that you can find this value from developer.apple.com when you creating app id. For example : 'BXTP48X8WA'\n       <2> If you want to resign the third ipa package with Enterprise distribution provision profile.\n\n       ption -ci: distribution name should be passed that you can find this value from keychain tools. For example: 'iPhone Distribution: Beijing xxx Network Technology Co., Ltd.', you should only pass 'Beijing xxx Network Technology Co., Ltd'.\n");
    printf("\nOPTIONS:\n       -d    your ipa absolute path.\n       -p    your mobileprovision absolute path.\n       -e    your entitlements file absolute path.\n       -id   your new bundle ID.\n       -ci   your certificate index,  you can find this value from keychain tools.\n       -py   the path of decompress icon implements python script.\n\n");
}
@end
