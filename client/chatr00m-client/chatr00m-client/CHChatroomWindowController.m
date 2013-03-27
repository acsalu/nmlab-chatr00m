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
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"jpg",@"gif",@"png",nil];    
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsOtherFileTypes:fileTypesArray];
    [openDlg setAllowsMultipleSelection:TRUE];
    
    NSString *filepath;
    if([openDlg runModal] == NSOKButton){
        NSLog(@"file chose");
        NSArray *files = [openDlg URLs];
        //NSLog(@"array:%@",files);
        NSLog(@"filename:%@",[[files objectAtIndex:0] path]);
        filepath = [[files objectAtIndex:0] path];
    }
    
    NSString *userIp = [NSString stringWithFormat:@"140.112.18.221"];
    NSDictionary *content = @{@"user_ip":userIp, @"file":filepath};
    [[CHCommunicationAgent sharedAgent] send:content forAction:ACTION_ASKTOSEND];
    
    //for testing
    NSString *receiverIp = @"localhost";
    [self initNetworkCommunicationWith:receiverIp];
    [self startSendingFile:content[@"file"]];
    
    
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

    if ([action isEqualToString:ACTION_AGREETORECEIVE]) {
        NSString *receiverIp = @"140.112.18.221";
        [self initNetworkCommunicationWith:receiverIp];
        [self startSendingFile:content[@"file"]];
    } else if ([action isEqualToString:ACTION_TALK]) {
        NSLog(@"%@:%@", content[@"name"], content[@"message"]);
        self.chatTableContents = [self.chatTableContents arrayByAddingObject:content];
        NSLog(@"%@", self.chatTableContents);
        [self.chatTableView reloadData];
    } else if ([action isEqualToString:ACTION_ROOMINFO] ) {
        self.userTableContents = content[@"room_client_info"];
        [self.userTableView reloadData];
    } else if([action isEqualToString:ACTION_ASKTOSEND]){
        NSString *file = content[@"file"];
        NSString *ip = @"140.112.18.221";
        NSDictionary *content = @{@"receiver_ip":ip, @"file":file};
        [[CHCommunicationAgent sharedAgent] send:content forAction:ACTION_AGREETORECEIVE];
        NSString *senderIp = @"140.112.18.219";
        [self initNetworkCommunicationWith:senderIp];
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

- (void)initNetworkCommunicationWith:(NSString *)ip
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    NSHost *host = [NSHost hostWithAddress:ip];
    NSLog(@"connecting to %@",ip);
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)(host), 10627, &readStream, &writeStream);
    self.inputstream = (__bridge NSInputStream *)readStream;
    self.outputstream = (__bridge NSOutputStream *)writeStream;
    [self.inputstream setDelegate:self];
    [self.outputstream setDelegate:self];
    [self.inputstream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputstream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
//- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"stream event %li", eventCode);
	
    if (eventCode == NSStreamEventHasBytesAvailable) {
        NSMutableData *data = [[NSMutableData alloc] init];
        
        //定義接收串流的大小
        uint8_t buf[1024];
        unsigned int len = 0;
        len = [(NSInputStream *)stream read:buf maxLength:1024];
        [data appendBytes:(const void *)buf length:len];
        
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"get string:%@",str);
        //將得到得的結果輸出到TextView上
        //textView.text = str;
    }
//	switch (eventCode) {
//			
//		case NSStreamEventOpenCompleted:
//			NSLog(@"Stream opened");
//			break;
//		case NSStreamEventHasBytesAvailable:
//            
//			if (stream == self.inputstream) {
//				
//				uint8_t buffer[1024];
//				int len;
//				
//				while ([self.inputstream hasBytesAvailable]) {
//					len = [self.inputstream read:buffer maxLength:sizeof(buffer)];
//					if (len > 0) {
//						
//						NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
//						
//						if (nil != self.outputstream) {
//                            
//							NSLog(@"server said: %@", output);
//							[self messageReceived:output];
//							
//						}
//					}
//				}
//			}
//			break;
//            
//			
//		case NSStreamEventErrorOccurred:
//			
//			NSLog(@"Can not connect to the host!");
//			break;
//			
//		case NSStreamEventEndEncountered:
//            
//            [aStream close];
//            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//            aStream = nil;
//			
//			break;
//		default:
//			NSLog(@"Unknown event");
//	}
}

- (void)messageReceived:(NSString *)message
{
    NSLog(@"message received...");
}

- (void) startSendingFile:(NSString *)filePath
{
    NSLog(@"start sending file");
    //NSImage *image = [[NSImage alloc] initWithContentsOfFile:filePath];
    //NSLog(@"image:%@",image);
    
    //NSString *response = [NSString stringWithFormat:@"testing"];
    //NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    NSString *str =@"iOS Login Success ...";
    const uint8_t *nuit8Text;
    nuit8Text = (uint8_t *) [str cStringUsingEncoding:NSASCIIStringEncoding];
    [self.outputstream write:nuit8Text maxLength:strlen((char*)nuit8Text)];
    //[self.outputstream write:[data bytes] maxLength:[data length]];
    NSLog(@"after sending file");
}

- (void) fileReceived:(NSString *)filePath
{
    
}

- (IBAction)declareReceiver:(id)sender
{
    NSLog(@"receiver got request...");
    NSString *senderIp = @"localhost";
    [self initNetworkCommunicationWith:senderIp];
}

@end
