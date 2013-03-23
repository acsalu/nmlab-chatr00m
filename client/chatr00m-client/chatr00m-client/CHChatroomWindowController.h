//
//  CHChatroomWindowController.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/23/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol CHCommunicationAgentDelegate;

@interface CHChatroomWindowController : NSWindowController <NSTextFieldDelegate, CHCommunicationAgentDelegate>


// UI components
@property (weak) IBOutlet NSTextField *messageTextField;

// room properties
@property NSInteger roomId;
@property (strong, nonatomic) NSString *title;


- (IBAction)sendMessage:(id)sender;
+ (CHChatroomWindowController *)chatroomWindowControllerWithRoomId:(int)roomId;

@end
