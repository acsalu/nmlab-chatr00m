//
//  CHAppDelegate.m
//  chatr00m-client
//
//  Created by Acsa Lu on 3/13/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import "CHAppDelegate.h"
#import "CHCommunicationAgent.h"
#import <CoreAudio/CoreAudio.h>
#import <PSMTabBarControl/PSMTabBarControl.h>
#import <PSMTabBarControl/PSMRolloverButton.h>


@implementation CHAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    self.agent = [CHCommunicationAgent sharedAgent];
    self.agent.delegate = self;
    
}


- (IBAction)send:(id)sender {
    [self.agent sendMessage:self.messageTextField.stringValue];
    self.messageTextField.stringValue = @"";
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    if ([[[obj userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement)
    {
        [self send:nil];
    }
}
//
//- (void)communicationAgent:(CHCommunicationAgent *)agent receiveMessage:(NSString *)message
//{
//    self.messageBoard.string = [NSString stringWithFormat:@"%@\n%@",  self.messageBoard.string, message];
//    
//    NSPoint newScrollOrigin;
//    
//    // assume that the scrollview is an existing variable
//    if ([[self.scrollView documentView] isFlipped]) {
//        newScrollOrigin=NSMakePoint(0.0,NSMaxY([[self.scrollView documentView] frame])
//                                    -NSHeight([[self.scrollView contentView] bounds]));
//    } else {
//        newScrollOrigin=NSMakePoint(0.0,0.0);
//    }
//    
//    [[self.scrollView documentView] scrollPoint:newScrollOrigin];
//}


@end
