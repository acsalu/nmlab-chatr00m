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
#import "JSONKit.h"
#import "CHChatroomController.h"

#define LOBBY_ROOM_ID 0

NSString *const POPULARITY_CELL_IDENTIFIER = @"PopularityCell";
NSString *const ROOM_CELL_IDENTIFIER = @"RoomCell";


@implementation CHAppDelegate

- (void)awakeFromNib
{
    self.chatroomList = [NSMutableArray array];
    [self.chatroomTableView setTarget:self];
    [self.chatroomTableView setDoubleAction:@selector(doubleClick:)];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    self.agent = [CHCommunicationAgent sharedAgent];
    self.agent.delegate = self;
    
    NSLog(@"local IP address: %@", [CHCommunicationAgent getIPAddress]);
    
}


- (IBAction)send:(id)sender {
    NSString *message = self.messageTextField.stringValue;
    NSLog(@"msg: %@", message);
    self.messageTextField.stringValue = @"";
    NSDictionary *content = @{@"room_id":@(LOBBY_ROOM_ID), @"message": message};
    [[CHCommunicationAgent sharedAgent] send:content forAction:ACTION_TALK];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    if ([[[obj userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement)
    {
        [self send:nil];
    }
}

- (void)reconnect:(id)sender
{
    [[CHCommunicationAgent sharedAgent] connect];
}

- (void)communicationAgent:(CHCommunicationAgent *)agent receiveMessage:(NSDictionary *)dic
{
    NSString *action = dic[@"action"];
    NSDictionary *content = dic[@"content"];
    
    if ([action isEqualToString:ACTION_ROOMLIST]) {
        NSRange range = NSMakeRange(0, [[self.chatroomArray arrangedObjects] count]);
        [self.chatroomArray removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
        for (NSDictionary *room in content[@"room_list"])
            [self.chatroomArray addObject:room];
    } else if ([action isEqualToString:ACTION_TALK]) {
        self.messageBoard.string = [NSString stringWithFormat:@"%@\n[%@]: %@",
                                    self.messageBoard.string, content[@"name"], content[@"message"]];
    }
    
}

- (IBAction)doubleClick:(id)sender
{
    
    NSInteger rowNumber = [self.chatroomTableView clickedRow];
//    NSLog(@"row %ld double clicked", rowNumber);
    NSDictionary *room = self.chatroomArray.content[rowNumber];
    int roomId = (int) [room[@"room_id"] integerValue];
    if (roomId == LOBBY_ROOM_ID) return;
    [self.chatroomController joinRoom:roomId];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
