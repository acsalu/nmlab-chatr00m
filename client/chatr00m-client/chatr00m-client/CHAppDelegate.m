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
#import "CHVLCWindowController.h"
#import "CHUsernameTextField.h"
#import "CHProfilePicCell.h"

#define LOBBY_ROOM_ID 0
#define USER_NAME_TEXTFIELD_TAG 1000

NSString *const POPULARITY_CELL_IDENTIFIER = @"PopularityCell";
NSString *const ROOM_CELL_IDENTIFIER = @"RoomCell";


@implementation CHAppDelegate

- (void)awakeFromNib
{
    self.chatroomList = [NSMutableArray array];
    [self.chatroomTableView setTarget:self];
    [self.chatroomTableView setDoubleAction:@selector(doubleClick:)];
    [NSApp beginSheet:self.welcomeSheet
       modalForWindow:self.window
        modalDelegate:self
       didEndSelector:NULL
          contextInfo:NULL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.agent = [CHCommunicationAgent sharedAgent];
    self.agent.delegate = self;
//    NSLog(@"local IP address: %@", [CHCommunicationAgent getIPAddress]);
}

- (IBAction)finishWelcomeSheet:(id)sender
{
    for (NSView *view in [self.welcomeSheet.contentView subviews]) {
        if (view.tag == USER_NAME_TEXTFIELD_TAG) {
            NSTextField *tf = (NSTextField *) view;
            NSLog(@"username = %@", tf.stringValue);
            self.usernameTextField.stringValue = tf.stringValue;
        } else if (view == self.profilePicCellwelcomeSheet) {
            self.profilePicCellMain.image = self.profilePicCellwelcomeSheet.image;
        }
    }
    [NSApp endSheet:self.welcomeSheet];
    [self.welcomeSheet close];
    self.welcomeSheet = nil;
    [self.window makeKeyAndOrderFront:self];

}

- (void)profilePicCell:(CHProfilePicCell *)profilePicCell isClicked:(BOOL)clicked
{
    [self.popover showRelativeToRect:[profilePicCell bounds] ofView:profilePicCell preferredEdge:NSMinYEdge];
}

- (IBAction)send:(id)sender {
    NSString *message = self.messageTextField.stringValue;
    NSLog(@"msg: %@", message);
    self.messageTextField.stringValue = @"";
    NSDictionary *content = @{@"room_id":@(LOBBY_ROOM_ID), @"message": message};
    [[CHCommunicationAgent sharedAgent] send:content forAction:ACTION_TALK];
}

- (IBAction)tryVLC:(id)sender
{
    if (!self.vlcWindowController) {
        self.vlcWindowController = [[CHVLCWindowController alloc] initWithWindowNibName:@"CHVLCWindowController"];
        [self.vlcWindowController showWindow:self];
    } else {
        [self.vlcWindowController.window makeKeyAndOrderFront:self];
    }
}

- (IBAction)pickUserImage:(id)sender
{
    NSButton *button = (NSButton *) sender;
    CHProfilePicCell *profilePicCell = (self.welcomeSheet) ? self.profilePicCellwelcomeSheet : self.profilePicCellMain;
    profilePicCell.image = button.image;
    [self.popover close];
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


#pragma  mark - CHUsernameTextFieldDelegate methods

- (void) usernameTextFieldIsClicked:(CHUsernameTextField *)usernameTextField
{
    [self.usernamePopover showRelativeToRect:[usernameTextField bounds] ofView:usernameTextField preferredEdge:NSMinYEdge];
}

#pragma mark - NSTextFieldDelegate methods

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    NSTextField *sender = (NSTextField *) [obj object];
    if ([[[obj userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement)
    {
        if (sender.tag == USER_NAME_TEXTFIELD_TAG) {
            self.usernameTextField.stringValue = sender.stringValue;
            [self.usernamePopover close];
        } else [self send:nil];
    }
}

@end
