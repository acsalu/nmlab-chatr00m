//
//  CHAppDelegate.m
//  chatr00m-client
//
//  Created by Acsa Lu on 3/13/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import "CHAppDelegate.h"
#import "CHCommunicationAgent.h"

@implementation CHAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.agent = [CHCommunicationAgent sharedAgent];
    self.agent.delegate = self;
    [self.agent startReading];
    
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

- (void)communicationAgent:(CHCommunicationAgent *)agent receiveMessage:(NSString *)message
{
    self.messageBoard.stringValue = [NSString stringWithFormat:@"%@\n%@", self.messageBoard.stringValue, message];
}


@end
