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

- (void)reconnect:(id)sender
{
    [[CHCommunicationAgent sharedAgent] connect];
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


- (void)communicationAgent:(CHCommunicationAgent *)agent receiveMessage:(NSDictionary *)dic
{
    NSString *action = dic[@"action"];
    NSDictionary *content = dic[@"content"];
    
    
    
    if ([action isEqualToString:ACTION_ROOMLIST]) {
        NSRange range = NSMakeRange(0, [[self.chatroomArray arrangedObjects] count]);
        [self.chatroomArray removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
        for (NSDictionary *room in content[@"room_list"])
            [self.chatroomArray addObject:room];
    }
    
}

- (IBAction)doubleClick:(id)sender
{
    
    NSInteger rowNumber = [self.chatroomTableView clickedRow];
//    NSLog(@"row %ld double clicked", rowNumber);
    NSDictionary *room = self.chatroomArray.content[rowNumber];
    int roomId = (int) [room[@"room_id"] integerValue];
    [self.chatroomController joinRoom:roomId];
}

@end
