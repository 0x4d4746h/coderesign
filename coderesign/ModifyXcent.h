//
//  ModifyXcent.h
//  coderesign
//
//  Created by MiaoGuangfa on 10/12/15.
//  Copyright © 2015 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ModifyXcent : NSObject

+ (ModifyXcent *) sharedInstance;

- (void)ModifyXcentWithFinishedBlock:(void(^)(BOOL isFinished))finishedBlock;

@end
