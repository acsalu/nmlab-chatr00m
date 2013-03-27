//
//  CHAppDelegate.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/13/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CHCommunicationAgent;
@protocol CHCommunicationAgentDelegate;
@class PSMTabBarControl;
@class CHChatRoomView;
@class CHChatroomController;
@class CHVLCWindowController;
@class CHUsernameTextField;

@interface CHAppDelegate : NSObject <NSApplicationDelegate, NSTextFieldDelegate, CHCommunicationAgentDelegate, NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *messageTextField;
@property (weak) IBOutlet CHUsernameTextField *userNameTextField;
@property (weak) CHCommunicationAgent* agent;
@property (unsafe_unretained) IBOutlet NSTextView *messageBoard;
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet CHChatroomController *chatroomController;


@property (weak) IBOutlet NSTableView *chatroomTableView;
@property (strong) NSMutableArray *chatroomList;
@property (weak) IBOutlet NSArrayController *chatroomArray;
@property (strong) CHVLCWindowController *vlcWindowController;

@property (weak) IBOutlet NSWindow *welcomeSheet;

- (IBAction)send:(id)sender;
- (IBAction)reconnect:(id)sender;
- (IBAction)finishWelcomeSheet:(id)sender;

- (IBAction)doubleClick:(id)sender;
- (IBAction)tryVLC:(id)sender;


@end
