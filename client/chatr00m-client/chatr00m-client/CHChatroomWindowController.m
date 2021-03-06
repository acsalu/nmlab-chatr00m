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
#import "CHAppDelegate.h"
#import "CHChatroomController.h";

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

- (IBAction)startNetService:(id)sender
{
    NSButton *button = (NSButton *) sender;
    
    if (!_service) {
        [button setTitle: @"Stop Net Service"];
        _service = [[NSNetService alloc] initWithDomain:@"" type:@"_ipp._tcp" name:@"Acsa's MBP" port:5555];
        _service.delegate = self;
        [_service publish];
    } else {
        [_service stop];
        [button setTitle: @"Start Net Service"];
    }
}

- (IBAction)startBrowser:(id)sender
{
    NSButton *button = (NSButton *) sender;
    if (!_browser) {
        [button setTitle: @"Stop Browser"];
        _browser = [[NSNetServiceBrowser alloc] init];
        _browser.delegate = self;
        [_browser searchForServicesOfType:@"_ipp.tcp" inDomain:@""];
    } else {
        [_browser stop];
        [button setTitle: @"Start Browser"];
    }
}

- (IBAction)inviteButtonClicked:(id)sender
{
    [self.popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxXEdge];
}

- (IBAction)confirmInvite:(id)sender
{
    NSInteger row = [self.onlineUsersTableView selectedRow];
    NSDictionary *content = @{@"client_id":((CHAppDelegate *) [NSApp delegate]).clientList[row][0], @"room_id":@(self.roomId)};
    [[CHCommunicationAgent sharedAgent] send:content forAction:ACTION_INVITE];
    [self.popover close];
}

- (IBAction)cancelInvite:(id)sender
{
    [self.popover close];
}

+ (CHChatroomWindowController *)chatroomWindowControllerWithId:(int)roomId Name:(NSString *)roomName andType:(enum RoomType)roomType
{
    CHChatroomWindowController *wc;
    //if (roomType == ROOM_TYPE_MESSAGE)
    //    wc = [[CHChatroomWindowController alloc] initWithWindowNibName:@"MessageWindow"];
    //else
        wc = [[CHChatroomWindowController alloc] initWithWindowNibName:@"ChatroomWindow"];
    wc.roomId = roomId;
    wc.roomType = roomType;
    wc.roomName = roomName;
    wc.window.title = [NSString stringWithFormat:@"chatroom[%d]-%@", roomId, roomName];
    if (roomType != ROOM_TYPE_MESSAGE) [wc.sendFileButton setHidden:YES];
    return wc;
}


- (IBAction)sendFileButtonPressed:(id)sender
{
}
    

//    
//    [openDlg beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
//        NSString *filepath;
//        NSLog(@"file chose");
//        NSArray *files = [openDlg URLs];
//        //NSLog(@"array:%@",files);
//        NSLog(@"filename:%@",[[files objectAtIndex:0] path]);
//        filepath = [[files objectAtIndex:0] path];
//        NSString *fileName = [[filepath lastPathComponent] stringByDeletingPathExtension];
//        NSString *fileType = [filepath pathExtension];
//        NSLog(@"file [%@][%@]", fileName, fileType);
//        NSData *data = [[NSFileManager defaultManager] contentsAtPath:filepath];
//        NSDictionary *content = @{@"room_id":@(self.roomId), @"file_name":fileName, @"file_type":fileType, @"file_data":data};
//        [[CHCommunicationAgent sharedAgent] send:content forAction:ACTION_SENDFILE];
//    }];
//    \
    
    

- (void)sendFile:(NSDictionary *)content
{
    [[CHCommunicationAgent sharedAgent] send:[[NSUserDefaults standardUserDefaults] objectForKey:@"file_to_send" ] forAction:ACTION_SENDFILE];
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
    if (((CHAppDelegate *) [NSApp delegate]).userId == (int) [otherUser[0] integerValue]) {
        NSLog(@"You can't talk with yourself asshole!");
        return;
    }
    NSLog(@"private talk with %@[%ld]", otherUser[1], (long)[otherUser[0] integerValue]);
    NSDictionary *content = @{@"client_id":otherUser[0]};
    [[CHCommunicationAgent sharedAgent] send:content forAction:ACTION_NEWMESSAGE];
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

- (NSInteger)profilePicIdxForClient:(NSInteger)clientId
{
    for (NSArray *client in self.userTableContents) {
        if ([client[0] integerValue] == clientId) {
            NSLog(@"%ld", [client[2] integerValue]);
            return [client[2] integerValue];
        }
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
        
        NSLog(@"%@:%@", content[@"client_name"], content[@"message"]);
        self.chatTableContents = [self.chatTableContents arrayByAddingObject:content];
        //NSLog(@"%@", self.chatTableContents);
        [self.chatTableView reloadData];
        
    } else if ([action isEqualToString:ACTION_ROOMINFO] ) {
        
        self.userTableContents = content[@"room_client_info"];
        [self.userTableView reloadData];
        [self.chatTableView reloadData];

        
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
    else return ((CHAppDelegate *) [NSApp delegate]).clientList.count;
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
        cellView.imageView.image = [NSImage imageNamed:[NSString stringWithFormat:@"user_img_0%ld", [user[2] integerValue]]];
    } else if ([identifier isEqualToString:@"ChatCell"]) {
        cellView = [tableView makeViewWithIdentifier:@"ChatCell" owner:self];
        NSLog(@"%@", self.chatTableContents);
        NSDictionary *chat = self.chatTableContents[row];
        NSInteger clientId = [chat[@"client_id"] integerValue];
        cellView.textField.stringValue = [NSString stringWithFormat:@"%@: %@", chat[@"client_name"], chat[@"message"]];
        cellView.imageView.image = [NSImage imageNamed:[NSString stringWithFormat:@"user_img_0%ld", [self profilePicIdxForClient:clientId]]];
    } else {
        cellView = [tableView makeViewWithIdentifier:@"OnlineUserCell" owner:self];
        NSArray *user = ((CHAppDelegate *) [NSApp delegate]).clientList[row];
        cellView.textField.stringValue = user[1];
        cellView.imageView.image = [NSImage imageNamed:[NSString stringWithFormat:@"user_img_0%ld", [user[2] integerValue]]];
    }
    
    return cellView;
}

# pragma mark - NSWindowDelegate methods

- (void)windowWillClose:(NSNotification *)notification
{
    // remove self from windows
    [((CHAppDelegate *) [NSApp delegate]).chatroomController.windowControllers removeObject:self];
    
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
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)ip, 10627, &readStream, &writeStream);
    CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    self.inputstream = (__bridge NSInputStream *)readStream;
    self.outputstream = (__bridge NSOutputStream *)writeStream;
    [self.inputstream setDelegate:self];
    [self.outputstream setDelegate:self];
    [self.inputstream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputstream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputstream open];
    [self.outputstream open];
}

//- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"stream event %li", eventCode);
	
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            NSLog(@"Output stream opened.");
            break;
            
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"has space");
            break;
        }
            
        case NSStreamEventEndEncountered: {
            NSLog(@"output stream closed");
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            break;
        }
            
        case NSStreamEventHasBytesAvailable:
        {
            NSLog(@"bytesAva");
            uint8_t *buffer;
            NSUInteger length;
            BOOL freeBuffer = NO;
            // The stream has data. Try to get its internal buffer instead of creating one
            if(![self.inputstream getBuffer:&buffer length:&length]) {
                // The stream couldn't provide its internal buffer. We have to make one ourselves
                buffer = malloc(1024 * sizeof(uint8_t));
                freeBuffer = YES;
                NSInteger result = [self.inputstream read:buffer maxLength:1024];
                if(result < 0) {
                    // error copying to buffer
                    break;
                }
                length = result;
            }
        }
        default:
            break;
    }//	switch (eventCode) {
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

- (void)messageReceived:(NSString *)message{
    NSLog(@"message received...");
}

- (void) startSendingFile:(NSString *)filePath
{
    NSLog(@"start sending file");
    //NSImage *image = [[NSImage alloc] initWithContentsOfFile:filePath];
    //NSLog(@"image:%@",image);
    //[image lockFocus];
    //NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:(0,0,image.size.width,image.size.height)];
    //[image unlockFocus];
    
    //NSString *response = [NSString stringWithFormat:@"testing"];
    //NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    //NSString *str =@"iOS Login Success ...";
    //const uint8_t *nuit8Text;
    //nuit8Text = (uint8_t *) [str cStringUsingEncoding:NSASCIIStringEncoding];
    //[self.outputstream write:nuit8Text maxLength:strlen((char*)nuit8Text)];
    //[self.outputstream write:[data bytes] maxLength:[data length]];
    //const char *buff	= “Hello World!”;
    //NSUInteger buffLen = strlen(buff);
    //NSInteger writtenLength = [self.outputstream write:(const uint8_t *)buff maxLength:strlen(buff)];
    //if (writtenLength != buffLen) {
    //    [NSException raise:@”WriteFailure” format:@””];
    //}
    NSString *response  = [NSString stringWithFormat:@"iam"];
	NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
	[self.outputstream write:[data bytes] maxLength:[data length]];
    NSLog(@"after sending file");
}

- (void) fileReceived:(NSString *)filePath
{
    
}

- (IBAction)declareReceiver:(id)sender
{
    NSLog(@"receiver got request...");
    NSString *senderIp = @"140.112.18.219";
    //[self initNetworkCommunicationWith:senderIp];
    [self setUpStreamForFile];
}

- (void)setUpStreamForFile
{
    self.inputstream = [[NSInputStream alloc] initWithFileAtPath:@"./"];
    [self.inputstream setDelegate:self];
    [self.inputstream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputstream open];
    
}

#pragma mark - NSNetServiceDelegate methods

- (void)netServiceWillPublish:(NSNetService *)sender
{
    NSLog(@"Bonjour is going to publish");
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    NSLog(@"Bonjour publish succeeded");
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    NSLog(@"Bonjour publish failed");
}

- (void)netServiceDidStop:(NSNetService *)sender
{
    sender.delegate = nil;
    self.service = nil;
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog(@"Bonjour did not resolve");
}
- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog(@"Bonjour did resolve address");
}

#pragma mark - NSNetServiceBrowserDelegate methods

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    NSLog(@"Bonjour is going to search");
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
    NSLog(@"Bonjour search stopped");
    browser.delegate = nil;
    self.browser = nil;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary *)errorInfo
{
    NSLog(@"Bonjour search failed");
    
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)more
{
    NSLog(@"Bonjour found service");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)more
{
    NSLog(@"Bonjour service removed");
}

@end
