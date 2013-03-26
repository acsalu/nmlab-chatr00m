//
//  CHChatroomWindowController.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/23/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Const.h"

@protocol CHCommunicationAgentDelegate;

<<<<<<< HEAD
@interface CHChatroomWindowController : NSWindowController <NSTextFieldDelegate, CHCommunicationAgentDelegate, NSApplicationDelegate, NSStreamDelegate>
=======
@interface CHChatroomWindowController : NSWindowController <NSTextFieldDelegate, CHCommunicationAgentDelegate, NSTableViewDataSource, NSTableViewDelegate>
>>>>>>> 7474b95f67e50af807414886bd98096d7dbd3f86


// UI components
@property (weak) IBOutlet NSTextField *messageTextField;

// room properties
@property NSInteger roomId;
@property (strong, nonatomic) NSString *roomName;
@property enum RoomType roomType;
<<<<<<< HEAD
@property (retain, nonatomic) NSOutputStream *outputstream;
@property (retain, nonatomic) NSInputStream *inputstream;
=======
@property (strong, nonatomic) NSMutableArray *userTableContents;
@property (weak) IBOutlet NSTableView *userTableView;
@property (weak) IBOutlet NSTableView *chatTableView;
>>>>>>> 7474b95f67e50af807414886bd98096d7dbd3f86

- (IBAction)sendMessage:(id)sender;
+ (CHChatroomWindowController *)chatroomWindowControllerWithId:(int)roomId Name:(NSString *)roomName andType:(enum RoomType)roomType;
- (IBAction)sendFile:(id)sender;
- (void)initNetworkCommunication;
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;
- (void)messageReceived:(NSString *)message;

@end
