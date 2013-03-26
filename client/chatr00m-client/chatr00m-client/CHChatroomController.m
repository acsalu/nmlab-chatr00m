//
//  CHChatroomController.m
//  chatr00m-client
//
//  Created by Acsa Lu on 3/23/13.
//  Copyright (c) 2013 com.nmlabg7. All rights reserved.
//

#import "CHChatroomController.h"
#import "CHChatroomWindowController.h"
#import "CHAppDelegate.h"
#import "CHCommunicationAgent.h"

#define CREATING_INDICATOR_TAG 1000
#define ROOMNAME_TITLE_TAG 2000
#define ROOMTYPE_PUBLIC_TAG 2001
#define ROOMTYPE_PRIVATE_TAG 2002

@implementation CHChatroomController




- (NSMutableArray *) windowControllers
{
    // lazy instantiation
    if (!_windowControllers) _windowControllers = [NSMutableArray array];
    return _windowControllers;
}

- (IBAction)activateSheet:(id)sender
{
    if (!_sheet) {
        [NSBundle loadNibNamed:@"NewRoomSheet" owner:self];
        [NSApp beginSheet:self.sheet
           modalForWindow:[[NSApp delegate] window]
            modalDelegate:self
           didEndSelector:NULL
              contextInfo:NULL];
    }
}

- (IBAction)createChatroomButtonPressed:(id)sender
{
    NSString *title;
    enum RoomType roomType;
    NSArray *subviews = [self.sheet.contentView subviews];
    for (NSView *view in subviews) {
        if (view.tag == ROOMNAME_TITLE_TAG) title = ((NSTextField *) view).stringValue;
        else if ([view class] == [NSMatrix class]) {
            NSMatrix *matrix = (NSMatrix *) view;
            if (((NSView *) [matrix selectedCell]).tag == ROOMTYPE_PRIVATE_TAG) roomType = ROOM_TYPE_PRIVATE;
            else roomType = ROOM_TYPE_PUBLIC;
        }
    }
    NSLog(@"[create-room] title:%@ type:%d", title, roomType);
    
    for (NSView *view in subviews) {
        if (view.tag == CREATING_INDICATOR_TAG) {
            NSTextField *creatingMessage = (NSTextField *) view;
            [creatingMessage setHidden:NO];
            creatingMessage.stringValue = [NSString stringWithFormat:@"Creating room %@...", title];
        } else if ([view class] == [NSProgressIndicator class]) {
            NSProgressIndicator *progressIndicator = (NSProgressIndicator *) view;
            [progressIndicator setHidden:NO];
            [progressIndicator startAnimation:self];
        } else {
            [view setHidden:YES];
        }
    }
    [[CHCommunicationAgent sharedAgent] send:@{@"room_name":title, @"room_type":[NSNumber numberWithInt:roomType]} forAction:ACTION_NEWROOM];
    
}

- (IBAction)closeSheet:(id)sender
{
    [NSApp endSheet:self.sheet];
    [self.sheet close];
    self.sheet = nil;
}

- (IBAction)createChatRoomWithTitle:(NSString *)title andType:(enum RoomType)type
{
    // TODO: retrieve roomId from server
    int roomId = 0;
    
}

- (IBAction)showChatroom:(id)sender
{
    
}

- (IBAction)joinRoom:(int)roomId
{
    NSLog(@"join room [%d]", roomId);
    
    // check whether the user is already in this room!
    CHChatroomWindowController *roomWindow = nil;
    for (CHChatroomWindowController *wc in self.windowControllers) {
        if (wc.roomId == roomId) {
            roomWindow = wc;
            break;
        }
    }
    
    if (roomWindow) {
        NSLog(@"already in room [%d]", roomId);
        [roomWindow.window makeKeyAndOrderFront:self];
    } else {
        [[CHCommunicationAgent sharedAgent] send:@{@"room_id": [NSNumber numberWithInteger:roomId]} forAction:ACTION_ENTERROOM];
    }
}

- (CHChatroomWindowController *)chatroomWindowControllerForRoomId:(int)roomId
{
    // refactor with NSCache
    CHChatroomWindowController *resultWindowController;
    if (!resultWindowController) {
        NSArray *resultArr = [self.windowControllers filteredArrayUsingPredicate:
                              [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                                CHChatroomWindowController *wc = (CHChatroomWindowController *) evaluatedObject;
                                return wc.roomId == roomId;
                                }]];
        if (resultArr.count != 0) {
            resultWindowController = resultArr[0];
        }
    }
    
    return resultWindowController;
}

# pragma mark - CHCommunicationAgentDelegate methods
- (void)communicationAgent:(CHCommunicationAgent *)agent receiveMessage:(NSDictionary *)dic
{
    NSString *action = dic[@"action"];
    NSDictionary *content = dic[@"content"];
    if ([action isEqualToString:ACTION_NEWROOM] || [action isEqualToString:ACTION_ENTERROOM]) {
        NSString *roomName = content[@"room_name"];
        int roomId = [content[@"room_id"] intValue];
        enum RoomType roomType = [content[@"room_type"] intValue];
        
        CHChatroomWindowController *wc = [CHChatroomWindowController chatroomWindowControllerWithId:roomId
                                                                                               Name:roomName
                                                                                            andType:roomType];
        [self.windowControllers addObject:wc];
        [wc showWindow:self];
        
        [self closeSheet:self];
    }
}

@end
