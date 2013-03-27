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

@interface CHChatroomWindowController : NSWindowController <NSTextFieldDelegate, CHCommunicationAgentDelegate, NSTableViewDataSource, NSTableViewDelegate, NSStreamDelegate, NSWindowDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate>


// UI components
@property (weak) IBOutlet NSTextField *messageTextField;
@property (weak) IBOutlet NSTableView *userTableView;
@property (weak) IBOutlet NSTableView *chatTableView;

// room properties
@property NSInteger roomId;
@property (strong, nonatomic) NSString *roomName;
@property enum RoomType roomType;
@property (retain, nonatomic) NSOutputStream *outputstream;
@property (retain, nonatomic) NSInputStream *inputstream;

@property (strong, nonatomic) NSDictionary *files;

@property (strong, nonatomic) NSArray *userTableContents;
@property (strong, nonatomic) NSArray *chatTableContents;

@property (strong) NSNetService *service;
@property (strong) NSNetServiceBrowser *browser;

- (IBAction)sendMessage:(id)sender;
+ (CHChatroomWindowController *)chatroomWindowControllerWithId:(int)roomId Name:(NSString *)roomName andType:(enum RoomType)roomType;
- (IBAction)sendFile:(id)sender;
- (void)initNetworkCommunicationWith:(NSString *)ip;
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;
- (void)messageReceived:(NSString *)message;

- (void)startSendingFile:(NSString *)filePath;
- (void)fileReceived:(NSString *)filePath;
- (IBAction)declareReceiver:(id)sender;
- (void) setUpStreamForFile;
- (IBAction)doubleClickedOnUser:(id)sender;



// test Bonjour
- (IBAction)startNetService:(id)sender;
- (IBAction)startBrowser:(id)sender;

@end
