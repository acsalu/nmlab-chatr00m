//
//  CHChatroomWindowController.m
//  chatr00m-client
//
//  Created by Acsa Lu on 3/23/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import "CHChatroomWindowController.h"
#import "CHCommunicationAgent.h"

@interface CHChatroomWindowController ()

@end

@implementation CHChatroomWindowController




+ (CHChatroomWindowController *)chatroomWindowControllerWithRoomId:(int)roomId
{
    CHChatroomWindowController *wc = [[CHChatroomWindowController alloc] initWithWindowNibName:@"ChatroomWindow"];
    wc.roomId = roomId;
    wc.window.title = [NSString stringWithFormat:@"chatroom[%d]-%@", roomId, @"untitiled"];
    return wc;
}

- (IBAction)sendMessage:(id)sender {
    NSString *message = self.messageTextField.stringValue;
    NSLog(@"msg: %@", message);
    NSNumber *roomId = [NSNumber numberWithInt:(int) self.roomId];
    self.messageTextField.stringValue = @"";
    NSDictionary *content = @{@"room_id":roomId, @"message": message};
    [[CHCommunicationAgent sharedAgent] send:content forAction:ACTION_TALK];
}

# pragma mark - NSTextFieldDelegate methods

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    if ([[[obj userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement)
    {
        [self sendMessage:self];
    }
}

# pragma mark - CHCommunicationAgentDelegate methods

- (void)communicationAgent:(CHCommunicationAgent *)agent receiveMessage:(NSDictionary *)dic
{
    
}


@end
