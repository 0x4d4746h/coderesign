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
    printf("%s%s%s%s%s%s%s%s%s%s%s%s%s%s",
           
           "\n                        CodeResign Tool General Commands Manual\n",
                        "Author:\n       MiaoGuangfa(0x4d4746h@gmail.com, @0x4d4746h)\n",
                        "Name:\n     coderesign -- resign the specific ipa file with yourself provisioning profile\n\n",
                        "SUPPORT LIST:\n",
                            "     Support decompress the icon file from ipa.\n"
                            "     Support check CPU construction for app.\n",
                            "     Support dump the specific app info.\n",
                            "     Support resign ipa file for Individual & Enterprise provision profile that related to developer or distribution cert.\n",
                        "HOW TO USE:\n",
                        "     1.Coderesign and decode icon png:\n"
                        "     coderesign -d /you/ipa/path/xx.ipa -p your_app.mobileprovision -ex your_watchkitextension.mobileprovision -wp your_watchkitapp_mobileprovision -se your_sharedExtension_mobileprovision -ci certificates_index -py your-python\n",
           
                        "     2.Only coderesign:\n     coderesign -d /you/ipa/path/xx.ipa -p your_app.mobileprovision -ex your_watchkitextension.mobileprovision -wp your_watchkitapp_mobileprovision -se your_sharedExtension_mobileprovision -ci certificates_index\n",
                        "ONE MORE THING:\n",
                        "       <1> If you want to resign the third ipa package with Individual distribution provision profile.\n\n       option -ci: App ID prefix should be passed that you can find this value from developer.apple.com when you creating app id. For example : 'BXTP48X8WA'\n       <2> If you want to resign the third ipa package with Enterprise distribution provision profile.\n\n       ption -ci: distribution name should be passed that you can find this value from keychain tools. For example: 'iPhone Distribution: Beijing xxx Network Technology Co., Ltd.', you should only pass 'Beijing xxx Network Technology Co., Ltd'.\n",
                        "OPTIONS:\n",
                        "       -d    your ipa absolute path.\n       -p    your app mobileprovision absolute path.\n       -ex    your watchkit extension mobileprovision absolute path.\n       -wp    your watchkit app mobileprovision absolute path.\n       -se    your shared extension mobileprovision absolute path.\n       -ci   your certificate index,  you can find this value from keychain tools.\n       -py   the path of decompress icon implements python script.\n\n"
           
           
           
           
           
           );
}
@end
