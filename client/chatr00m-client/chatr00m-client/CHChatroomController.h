//
//  CHChatroomController.h
//  chatr00m-client
//
//  Created by Acsa Lu on 3/23/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHChatroomWindowController;

@interface CHChatroomController : NSObject

@property (weak) IBOutlet NSView *view;
@property (weak) IBOutlet NSTabView *tabView;
@property (strong, nonatomic) NSMutableArray *windowControllers;

- (IBAction)newChatroom:(id)sender;
- (IBAction)showChatroom:(id)sender;

- (CHChatroomWindowController *)chatroomWindowControllerForRoomId:(int)roomId;

@end
