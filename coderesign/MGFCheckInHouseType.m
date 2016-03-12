//
//  MGFCheckInHouseType.m
//  coderesign
//
//  Created by MiaoGuangfa on 3/12/16.
//  Copyright © 2016 MiaoGuangfa. All rights reserved.
//

#import "MGFCheckInHouseType.h"

@implementation MGFCheckInHouseType

- (void)mgf_checkIfInHouseType
{
#if CHECK_INHOUSE_TYPE
    NSDictionary *dic = [[NSDictionary alloc]initWithContentsOfFile:self.mgfSharedData.normalDecodeMobileProvisionPlistPath];
    BOOL _tag = (BOOL)[dic objectForKey:@"ProvisionsAllDevices"];
    if (_tag) {
        self.mgfSharedData.isInHouseType = TRUE;
        [DebugLog showDebugLog:@"IPA is In-House type" withDebugLevel:Debug];

        NSDictionary *_inhouse_type = @{@"ProvisionsAllDevices"       :   @(_tag)};
        NSData *objData = [NSJSONSerialization dataWithJSONObject:_inhouse_type options:NSJSONWritingPrettyPrinted error:nil];
        NSString *jsonString = [[NSString alloc]initWithData:objData encoding:NSUTF8StringEncoding];

        NSString *_resutl = [@"<InHouse>" stringByAppendingFormat:@"%@</InHouse>",jsonString];
        [DebugLog showDebugLog:_resutl withDebugLevel:Info];
    }else{
        [DebugLog showDebugLog:@"IPA is NOT In-House type" withDebugLevel:Debug];
    }
#endif
    [self mgf_invokeDelegate:self withFinished:TRUE withObject:nil];
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}
@end
