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

- (void)awakeFromNib
{
    self.userTableContents = [NSMutableArray array];
    NSString *path = @"/Library/Application Support/Apple/iChat Icons/Tribal Masks";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtPath:path];
    
    NSString *file;
    while (file = [directoryEnumerator nextObject]) {
        NSString *filePath = [path stringByAppendingFormat:@"/%@", file];
        NSDictionary *obj = @{@"image":[[NSImage alloc] initByReferencingFile:filePath],
                              @"name":[file stringByDeletingPathExtension]};
        [self.userTableContents addObject:obj];
    }
}

+ (CHChatroomWindowController *)chatroomWindowControllerWithId:(int)roomId Name:(NSString *)roomName andType:(enum RoomType)roomType
{
    CHChatroomWindowController *wc;
    if (roomType == ROOM_TYPE_MESSAGE)
        wc = [[CHChatroomWindowController alloc] initWithWindowNibName:@"MessageWindow"];
    else
        wc = [[CHChatroomWindowController alloc] initWithWindowNibName:@"ChatroomWindow"];
    wc.roomId = roomId;
    wc.roomType = roomType;
    wc.roomName = roomName;
    wc.window.title = [NSString stringWithFormat:@"chatroom[%d]-%@", roomId, roomName];
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
    NSString *action = dic[@"action"];
    NSDictionary *content = dic[@"content"];
    if ([action isEqualToString:ACTION_TALK]) {
        
    }
}

# pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.userTableContents.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *user = self.userTableContents[row];
    
    // may use for more than 1 column
    NSString *identifier = [tableColumn identifier];
    
    if ([identifier isEqualToString:@"UserCell"]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"UserCell" owner:self];
        cellView.textField = user[@"name"];
        cellView.imageView.image = user[@"image"];
        
        return cellView;
    }
    return nil;
}

# pragma mark - NSWindowDelegate methods

- (void)windowWillClose:(NSNotification *)notification
{
    NSDictionary *content = @{@"room_id":[NSNumber numberWithInteger:self.roomId]};
    [[CHCommunicationAgent sharedAgent] send:content forAction:ACTION_LEAVEROOM];
}


@end
