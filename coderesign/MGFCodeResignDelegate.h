//
//  MGFCodeResignDelegate.h
//  coderesign
//
//  Created by MiaoGuangfa on 3/11/16.
//  Copyright © 2016 MiaoGuangfa. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MGFCodeResignDelegate <NSObject>

- (void) MGFCodeResignDelegate:(id) obj withFinished:(BOOL) isFinished withObject:(id) object;

@end
