//
//  CHChatroomController.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/23/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Const.h"

@class CHChatroomWindowController;
@protocol CHCommunicationAgentDelegate;

@interface CHChatroomController : NSObject <CHCommunicationAgentDelegate>

@property (strong, nonatomic) NSMutableArray *windowControllers;
@property (weak) IBOutlet NSWindow *sheet;


- (IBAction)createChatroomButtonPressed:(id)sender;
- (IBAction)showChatroom:(id)sender;
- (IBAction)activateSheet:(id)sender;
- (IBAction)closeSheet:(id)sender;

- (IBAction)joinRoom:(int)roomId;


- (CHChatroomWindowController *)chatroomWindowControllerForRoomId:(int)roomId;

@end
