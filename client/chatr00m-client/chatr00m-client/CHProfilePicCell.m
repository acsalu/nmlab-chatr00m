//
//  CHProfilePicCell.m
//  chatr00m-client
//
//  Created by Acsa Lu on 3/16/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import "CHProfilePicCell.h"
#import "NSOpenPanel+CHOpenPanel.h"
#import "CHCommunicationAgent.h"

@implementation CHProfilePicCell

- (void)mouseDown:(NSEvent *)theEvent
{
    //if (self.clicked) return;
    self.clicked = YES;
    NSLog(@"change profile pic");
    [self.delegate profilePicCell:self isClicked:self.clicked];
}


@end
