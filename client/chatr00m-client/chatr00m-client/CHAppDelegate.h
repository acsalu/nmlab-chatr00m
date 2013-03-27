//
//  CHAppDelegate.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/13/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol CHCommunicationAgentDelegate;
@protocol CHProfilePicCellDelegate;
@protocol CHUsernameTextFieldDelegate;

@class CHCommunicationAgent;
@class PSMTabBarControl;
@class CHChatRoomView;
@class CHChatroomController;
@class CHVLCWindowController;
@class CHUsernameTextField;
@class CHProfilePicCell;
@class CHUsernameTextField;

@interface CHAppDelegate : NSObject
    <NSApplicationDelegate, NSTextFieldDelegate, CHCommunicationAgentDelegate, NSTableViewDataSource,
     NSTableViewDelegate, NSWindowDelegate, CHProfilePicCellDelegate, CHUsernameTextFieldDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *messageTextField;
@property (weak) CHCommunicationAgent* agent;
@property (unsafe_unretained) IBOutlet NSTextView *messageBoard;
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet CHChatroomController *chatroomController;

@property (weak) IBOutlet CHProfilePicCell *profilePicCellMain;
@property (weak) IBOutlet CHUsernameTextField *usernameTextField;

@property (weak) IBOutlet NSTableView *chatroomTableView;
@property (strong) NSMutableArray *chatroomList;
@property (weak) IBOutlet NSArrayController *chatroomArray;
@property (strong) CHVLCWindowController *vlcWindowController;

@property (weak) IBOutlet NSWindow *welcomeSheet;
@property (weak) IBOutlet CHProfilePicCell *profilePicCellwelcomeSheet;


@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSPopover *usernamePopover;

@property int imgIdx;
@property int userId;

- (IBAction)send:(id)sender;
- (IBAction)reconnect:(id)sender;
- (IBAction)finishWelcomeSheet:(id)sender;

- (IBAction)doubleClick:(id)sender;
- (IBAction)tryVLC:(id)sender;

- (IBAction)pickUserImage:(id)sender;


@end
