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

@interface CHChatroomWindowController : NSWindowController <NSTextFieldDelegate, CHCommunicationAgentDelegate, NSTableViewDataSource, NSTableViewDelegate>


// UI components
@property (weak) IBOutlet NSTextField *messageTextField;

// room properties
@property NSInteger roomId;
@property (strong, nonatomic) NSString *roomName;
@property enum RoomType roomType;
@property (strong, nonatomic) NSMutableArray *userTableContents;
@property (weak) IBOutlet NSTableView *userTableView;
@property (weak) IBOutlet NSTableView *chatTableView;

- (IBAction)sendMessage:(id)sender;
+ (CHChatroomWindowController *)chatroomWindowControllerWithId:(int)roomId Name:(NSString *)roomName andType:(enum RoomType)roomType;

@end
