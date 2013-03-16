//
//  NSOpenPanel+CHOpenPanel.m
//  chatr00m-client
//
//  Created by Acsa Lu on 3/16/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import "NSOpenPanel+CHOpenPanel.h"

@implementation NSOpenPanel (CHOpenPanel)

- (void)setLevel:(NSInteger)newLevel
{
    [super setLevel:CGShieldingWindowLevel()];
}

@end
