//
//  CHChatroomWindowController.m
//  chatr00m-client
//
//  Created by Acsa Lu on 3/23/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import "CHChatroomWindowController.h"
#import "CHCommunicationAgent.h"
#import "CHProfilePicCell.h"

@interface CHChatroomWindowController ()

@end

@implementation CHChatroomWindowController

- (void)awakeFromNib
{
    [self.userTableView setTarget:self];
    [self.userTableView setDoubleAction:@selector(doubleClickedOnUser:)];
}


- (NSArray *) chatTableContents
{
    if (!_chatTableContents) _chatTableContents = [[NSArray alloc] init];
    return _chatTableContents;
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



- (IBAction)sendFile:(id)sender {
    [self initNetworkCommunication];
    NSString *response = [NSString stringWithFormat:@"testing"];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [self.outputstream write:[data bytes] maxLength:[data length]];
}

- (IBAction)sendMessage:(id)sender {
    NSString *message = self.messageTextField.stringValue;
    NSLog(@"msg: %@", message);
    NSNumber *roomId = [NSNumber numberWithInt:(int) self.roomId];
    self.messageTextField.stringValue = @"";
    NSDictionary *content = @{@"room_id":roomId, @"message": message};
    [[CHCommunicationAgent sharedAgent] send:content forAction:ACTION_TALK];
}

- (IBAction)doubleClickedOnUser:(id)sender
{
    NSInteger row = [self.userTableView clickedRow];
    NSLog(@"double click on row %ld", row);
    if (row < 0) {
        NSLog(@"invalid row");
        return;
    }
    NSArray *otherUser = self.userTableContents[row];
    NSLog(@"private talk with %@[%ld]", otherUser[1], (long)[otherUser[0] integerValue]);
    // check if the user is self
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
        NSLog(@"%@:%@", content[@"name"], content[@"message"]);
        self.chatTableContents = [self.chatTableContents arrayByAddingObject:content];
        NSLog(@"%@", self.chatTableContents);
        [self.chatTableView reloadData];
    } else if ([action isEqualToString:ACTION_ROOMINFO] ) {
        self.userTableContents = content[@"room_client_info"];
        [self.userTableView reloadData];
    }
}

# pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.userTableView) return self.userTableContents.count;
    else if (tableView == self.chatTableView) return self.chatTableContents.count;
    else return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    
    // may use for more than 1 column
    NSString *identifier = [tableColumn identifier];
    NSTableCellView *cellView = nil;
    
    if ([identifier isEqualToString:@"UserCell"]) {
        cellView = [tableView makeViewWithIdentifier:@"UserCell" owner:self];
        NSArray *user = self.userTableContents[row];
        //cellView.textField.stringValue = user[@"name"];
        //cellView.imageView.image = user[@"image"];
        cellView.textField.stringValue = user[1];
        cellView.imageView.image = [CHProfilePicCell profilePicForIndex:1];
    } else if ([identifier isEqualToString:@"ChatCell"]) {
        cellView = [tableView makeViewWithIdentifier:@"ChatCell" owner:self];
        NSLog(@"%@", self.chatTableContents);
        NSDictionary *chat = self.chatTableContents[row];
        cellView.textField.stringValue = chat[@"message"];
//        cellView.imageView.image = user[@"image"];
    }
    
     return cellView;
}

# pragma mark - NSWindowDelegate methods

- (void)windowWillClose:(NSNotification *)notification
{
    NSDictionary *content = @{@"room_id":[NSNumber numberWithInteger:self.roomId]};
    [[CHCommunicationAgent sharedAgent] send:content forAction:ACTION_LEAVEROOM];
}

# pragma mark - InitCommunicaiton

- (void)initNetworkCommunication
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    NSHost *host = [NSHost hostWithAddress:@"140.112.18.211"];
    NSLog(@"connecting");
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)(host), 10627, &readStream, &writeStream);
    self.inputstream = (__bridge NSInputStream *)readStream;
    self.outputstream = (__bridge NSOutputStream *)writeStream;
    [self.inputstream setDelegate:self];
    [self.outputstream setDelegate:self];
    [self.inputstream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputstream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"stream event %i", eventCode);
	
	switch (eventCode) {
			
		case NSStreamEventOpenCompleted:
			NSLog(@"Stream opened");
			break;
		case NSStreamEventHasBytesAvailable:
            
			if (aStream == self.inputstream) {
				
				uint8_t buffer[1024];
				int len;
				
				while ([self.inputstream hasBytesAvailable]) {
					len = [self.inputstream read:buffer maxLength:sizeof(buffer)];
					if (len > 0) {
						
						NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
						
						if (nil != self.outputstream) {
                            
							NSLog(@"server said: %@", output);
							[self messageReceived:output];
							
						}
					}
				}
			}
			break;
            
			
		case NSStreamEventErrorOccurred:
			
			NSLog(@"Can not connect to the host!");
			break;
			
		case NSStreamEventEndEncountered:
            
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            aStream = nil;
			
			break;
		default:
			NSLog(@"Unknown event");
	}
}

- (void)messageReceived:(NSString *)message
{
    NSLog(@"message received...");
}

@end
